def check(position, currentposition, landscapes):
    firststatement = landscapes[0][0] <= position <=landscapes[0][1]
    secondstatement = landscapes[1][0] <= position <= landscapes[1][1]
    thirdstatement = landscapes[2][0] <= position <= landscapes[2][1]
    
    if landscapes[0][0] != 1:
        fourthstatement = currentposition<=landscapes[0][0]+6 and firststatement
    else:
        fourthstatement = currentposition<=96 and firststatement

    fifthstatement = currentposition <= landscapes[1][0]+6 and secondstatement
    sixthstatement = currentposition <= landscapes[2][0]+6 and thirdstatement

    if fourthstatement or fifthstatement or sixthstatement:
        return True 
    return False

def checkValidMoves(position, currentposition, colour, lapenabled):
    home =[[10,20], [34,44], [58,68], [82,92]]
    landscapes = []

    if colour == "red":
        landscapes =[[26,27],[50,61],[74,85]]
    elif colour == "yellow":
        landscapes = [[1,13], [50,61], [74,85]]
    elif colour == "blue":
        landscapes = [[1,13],[26,37],[74,85]]
    elif colour == "green":
        landscapes = [[1,13],[26,37],[50,61]]

    if check(position, currentposition, landscapes):
        return position + 7
    elif (home[0][0] <= position <=home[0][1]) and lapenabled:
        return position - 8
    elif position == home[0][0] -1 and lapenabled:
        return 97 
    else:
        return position

def validateBoardlimit(position):
    if position > 96:
        return position - 96
    return position

def possibleMoves(pawn, diea, dieb):
    total = diea + dieb 
    total = validateBoardlimit(total)
    validiea = validateBoardlimit(diea + pawn["position"])
    validieb = validateBoardlimit(dieb + pawn["position"])

    validtotal = checkValidMoves(total, pawn["position"] ,pawn["colour"], pawn["lapenabled"])
    validiea = checkValidMoves(validiea, pawn["position"] ,pawn["colour"], pawn["lapenabled"])
    validieb = checkValidMoves(validieb, pawn["position"] ,pawn["colour"], pawn["lapenabled"])

    validmoves = [validtotal, validiea, validieb]

    if pawn["position"] in validmoves:
        validmoves.remove(pawn["position"])

    validmovestring = '{"validmoves": '
    print 'Validmoves:'
    for x in validmoves:
        print x
        validmovestring += x +','
    print '----ValidMoves----'
    
    if validmovestring[-1:] == ',':
        validmovestring = validmovestring[:-1]

    validmovestring += '}\n' 
    return validmovestring

def createTransitionString(player,playerid):
    transtring = '{"'
    transtring += playerid + '":'

    for pawn, position in player.iteritems():
        transtring += '"' + pawn +'":' + position +','
    
    if transtring[-1:] == ',':
        transtring = transtring[:-1]

    transtring += '}'
    
    return transtring
        