def checkJailing(otherPlayers, safespots, player):
    playerPawnPositions = []
    jailstring = '"jailedpawns":{'
    jailedpawnstring =''
    for pawn in player:
        print("PAWN: ", pawn,pawn not in ['out','endturn'] )
        if pawn not in ['out','endturn', 'updateposition']:
            pawnposition = player[pawn]["position"] 
            if pawnposition != 97:
                playerPawnPositions.append(player[pawn]["position"])
    print "PLAYERPAWNS: ",playerPawnPositions
    for playerid, otherPlayer in otherPlayers.iteritems():
        if otherPlayer != player:
            jailedpawns = ''
            for pawn in otherPlayer:
                if pawn not in ['out','endturn', 'updateposition']:
                    print otherPlayer[pawn]["position"],
                    if otherPlayer[pawn]["position"] not in safespots and otherPlayer[pawn]["position"] in playerPawnPositions:
                        jailedpawns += str(otherPlayer[pawn]["position"]) + ','
            if jailedpawns[-1:] == ',':
                jailedpawns = jailedpawns[:-1]
            if jailedpawns != '':
                jailedpawnstring += playerid +'":[' + jailedpawns +'],'
    if jailedpawnstring != '':
        if jailedpawnstring[-1:] == ',':
            jailedpawnstring = jailedpawnstring[:-1]
        jailstring += jailedpawnstring + ', "anyjailed": true'
    else:
        jailstring += '"anyjailed": false'
    jailstring += '}'

    return jailstring
