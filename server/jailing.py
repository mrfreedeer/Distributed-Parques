def checkJailing(otherPlayers, safespots, player):
    playerPawnPositions = []
    jailstring = '"jailedpawns":{'
    jailedpawnstring =''
    for pawn in player:
        playerPawnPositions.append(pawn["position"])

    for otherPlayer in otherPlayers:
        jailedpawns = ''
        for pawn in otherPlayer:
            if pawn["position"] not in safespots and pawn["position"] in playerPawnPositions:
                jailedpawns += pawn["position"] + ','
        if jailedpawns[-1:] == ',':
            jailedpawns = jailedpawns[:-1]
        if jailedpawns != '':
            jailedpawnstring += otherPlayer["playerid"] +'":[' + jailedpawns +'],'
    if jailedpawnstring != '':
        if jailedpawnstring[-1:] == ',':
            jailedpawnstring = jailedpawnstring[:-1]
        jailstring += jailedpawnstring + ', "anyjailed": true'
    else:
        jailstring += '"anyjailed": false'
    jailstring += '}'

    return jailstring
