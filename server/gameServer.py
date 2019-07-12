import socket
import threading
import json
import time
import random
import re
import operator
from itertools import cycle 
from datetime import datetime
from playermovement import *
from jailing import *

stocknames = ["Panda", "Serpiente", "Oso", "Hormiga" ]
safespots = [1,13,20,25,37,44,49,61,68,73,85,92]
players = {}
availablecolours = ["red", "blue", "green", "yellow"]
clients = {}
clientsid = []
chosencolours = {}
receivedcolours = False
transitiontest = '{"transition":true, "playerspositions": {"player1": {"pawn1": 22 , "pawn2": 56, "pawn3": 65 , "pawn4": 55}, "player2": {"pawn1": 13 , "pawn2": 13, "pawn3": 13 , "pawn4": 13}}}\n'
jailedtest = '{"jailedpawns": {"player2": [70]}}\n'
playerstring = "player"
playernumber = 1
maxplayers = False
isGameOn = False
clientpool = cycle(clientsid)
startdicerolls = {}


def timeAdjustment(timestring):
    othertime = json.loads(timestring)
    time = datetime.now().time()
    print(time, "SERVERTIME")
    diffstring = '{"hours": '
    diffstring += str(time.hour - othertime["hours"]) + ', "minutes": '
    diffstring += str(time.minute - othertime["minutes"]) + ', "seconds": '
    diffstring += str(time.second - othertime["seconds"]) +'}\n'
    
    return diffstring

def getColours(availablecolours):
    colourstr = '{"colours": "'
    
    for x in availablecolours:
        print x
        colourstr = colourstr + x + ","
    colourstr = colourstr[:-1]      
    return colourstr + '"}\n'

def test(client):
    print "TESTING"
    newplayerstring ='{"newplayer":true, "playerid" : "player2", "colour" : "blue"}\n'
    client.send(newplayerstring)
    time.sleep(.2)
    client.send('{"startgame":true}\n')
    time.sleep(.2)
    client.send(transitiontest)
    time.sleep(1)
    client.send('{"turngranted":true}\n')
    #client.send(jailedtest)
    

def grantTurn():
    clientid = next(clientpool)
    print "Next: ", clientid 
    waitingclient = clients[clientid]
    grantstr = '{"turngranted":true,' 
    grantstr += '"playerid": "' + clientid + '"}\n'
    hasturnstr = '{"hasturn":"' + clientid +'"}\n' 
    waitingclient.send(grantstr)
    for key, otherclient in clients.iteritems():
        print "KEY: ", key, " CLIENTID:", clientid
        if key != clientid: 
            otherclient.send(hasturnstr) 
    

def updateInfo():
    pass

class Receive(threading.Thread):
    def __init__(self, client, addr, id):
            super(Receive,self).__init__()
            self.client = client
            self.addr = addr
            self.clientid = id
    def run(self):
        global isGameOn
        global safespots
        while True:
           incoming = self.client.recv(1024)
           print "----->", incoming
           data = json.loads(incoming)
           if data:
            if "start" in data: 
                if not isGameOn:
                    if playernumber >= 3:
                        for key, client in clients.iteritems():
                            rannumber = random.randint(1000000,10000000)
                            client.send('{"startgame": true, "randomnum":' + str(rannumber) + '}\n')
                        isGameOn = True
                       # grantTurn()
                    else:
                        self.client.send('{"waiting":true}\n')
            elif "startroll" in data:
                startdicerolls[self.clientid] = data["startroll"]
                print len (startdicerolls), playernumber - 1, max(startdicerolls.iteritems(), key=operator.itemgetter(1))[0]
                if  len (startdicerolls) == (playernumber - 1):
                    starter = max(startdicerolls.iteritems(), key=operator.itemgetter(1))[0]
                    while next(clientpool) != starter:
                        pass
                    grantstr = '{"turngranted":true,' 
                    grantstr += '"playerid": "' + starter + '"}\n'
                    clients[starter].send(grantstr)
                    hasturnstr = '{"hasturn":"' + starter +'"}\n' 
                    for key, otherclient in clients.iteritems():
                        if key != starter: 
                            otherclient.send(hasturnstr) 
            else:
                if "possibleMoves" in data:
                    pawn = players[self.clientid][data["pawn"]]
                    validmoves = possibleMoves(pawn, data["dice"][0], data["dice"][1])
                    self.client.send(validmoves)
                elif "updateposition" in data:
                    regexresult = re.match('(.*?), "u',incoming).group()
                    regexresult = regexresult[:-4]
                    regexresult += '}'
                    players[self.clientid] = json.loads(regexresult)
                elif "endturn" in data:
                    if data["out"]:
                        regexresult = re.match('(.*?), "e',incoming).group()
                        regexresult = regexresult[:-4]
                        regexresult += '}'
                        players[self.clientid] = json.loads(regexresult)

                        jailing = checkJailing(players, safespots, players[self.clientid])
                        transition = createTransitionString(players[self.clientid], self.clientid)
                        updateinfo = '{' + jailing +',' + transition + '}\n'
                        
                        self.client.send('{'+jailing+'}\n')
                        
                        for key, client in clients.iteritems():
                            if key != self.clientid: 
                                client.send(updateinfo)
                    grantTurn()
               
                   
                    
                   

servsocket = socket.socket()

servsocket.bind(("", 8000))
servsocket.listen(4)
colour = ""
print "Parques Server Running..."


while True:
    if not maxplayers and not isGameOn:
        receivedcolours = False
        c, addr = servsocket.accept()
        clientime = c.recv(1024)
        print clientime 
        c.send(timeAdjustment(clientime))
        
        colours = getColours(availablecolours)
        print ('Connection from: ', addr)
        while not receivedcolours:
            c.send(colours)
            ack = c.recv(1024)
            if ack == 'true':
                playerid =c.recv(1024)
                if playerid == '':
                    playerid = stocknames[random.randint(0,3)]
                    stocknames.remove(playerid)
                colour = c.recv(1024)
                createdplayer = c.recv(1024)
                createdplayer = json.loads(createdplayer)
                players[playerid] = createdplayer
                chosencolours[playerid] = colour
                availablecolours.remove(colour)
                print('Current colours: ', availablecolours)
                receivedcolours = True
            

      
        for key, client in clients.iteritems():
            newplayerstring ='{"newplayer":true, "playerid" : "'+ playerid + '", "colour" : "' + colour + '"}\n'
            allplayersforclient = '{"newplayer":true, "playerid" : "'+ key + '", "colour" : "' + chosencolours[key] + '"}\n'
            client.send(newplayerstring)
            c.send(allplayersforclient)

        #test(c)
        playernumber += 1
        clients[playerid]= c
        clientsid.append(playerid)

        t = Receive(c,addr, playerid)
        t.start()



servsocket.close()
