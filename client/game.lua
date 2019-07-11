-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local everything
local boardlib = require "board"
local widget = require "widget"

local halfH = display.contentHeight * 0.5
local halfW = display.contentWidth * 0.5
local diea = nil
local dieb = nil
local movespeed = 1
local center = {halfW, halfH}
local globalboard
local blackies
local yellowlimit = 48
local bluelimit = 72
local greenlimit = 96
local player = {}
local blackies = {}
local tappedpawn = nil
local pawnToTake = nil
local blockMessage = false
turnText = {}
local otherPlayers = {}
local equaldice = false
testing = true
pawnsOut = {}
local jailedPawns = {}
-----   Test Area ----------
----------------------------
local otherplayersinfo = testing
local start = testing
local turn = testing 
----------------------------
local takePawn = false
local pawnsToRemove = {}

player.name ="lolita"
player.out = false
player.colour = chosencolour
player.rolled = false
player.hasExitedBefore = false
player.playerid = playerid
timesRolled = 0



function drawInJail(player, homecolour)
    player[1].x = homecolour[1]-20
    player[1].y = homecolour[2]-20
    player[2].x = homecolour[1]+20
    player[2].y = homecolour[2]-20
    player[3].x = homecolour[1]-20
    player[3].y = homecolour[2]+20
    player[4].x = homecolour[1]+20
    player[4].y = homecolour[2]+20
end

function createplayer(player)
    for i=1,4 do
       circle = display.newCircle(0,0,5)
       circle.out = false
       circle.auxlap = false
       circle.lap = false
       circle.colour = player.colour
        if player.colour == "red" then
            circle.pos = 13
            circle:setFillColor(1,0,0)
        elseif player.colour == "yellow" then 
            circle.pos = 37
            circle:setFillColor(1,1,0)
        elseif player.colour == "blue" then
            circle:setFillColor(0,0,1)
            circle.pos = 61
        elseif player.colour == "green" then
            circle:setFillColor(0,1,0)
            circle.pos = 85
        end
        circle:setStrokeColor(.2,.2,.2)
        circle.strokeWidth = 1
        table.insert(player,circle)
    end
    print("sending info")
    comms.sendinfo(player, false)
end

createplayer(player)

local function paintTiles(pawn) 
    for i, cell in ipairs(pawn.validmoves) do
        print(cell)
        globalboard[cell]:setFillColor(.35,.2,.86)
    end
end

local function exitprison(player) --Salir de la prision

    print(player.name, " exitedprison")
    player.out = true
    if not player.hasExitedBefore then 
        for i, pawn in ipairs(player) do
            pawn.out = true
            pawn.x = globalboard[pawn.pos].x
            pawn.y = globalboard[pawn.pos].y
        end
    else 
        reset = boardlib.resetPos(player)
        for i, pawn in ipairs(player) do
           if pawn.pos == reset then 
                pawn.out = true
                pawn.x = globalboard[pawn.pos].x
                pawn.y = globalboard[pawn.pos].y
           end 
        end
    end 

    player.hasExitedBefore = true
end


function tellHomeColour(player)
    if player.colour == "red" then
        homec = homeredpos 
    elseif player.colour == "blue" then
        homec = homebluepos 
    elseif player.colour == "green" then
        homec = homegreenpos
    elseif player.colour == "yellow" then
        homec = homeyellowpos
    end
    return homec
end

function restoreColourBoard(pawn) 
    if(pawn.validmoves ~= nil) then   

        for i, cell in ipairs(pawn.validmoves) do
            if table.indexOf(blackies, cell) == nil then
                colour = boardlib.tellColour(cell)
                if colour == "solidred" then
                    globalboard[cell]:setFillColor(1, 0, 0)
                elseif colour == "solidyellow" then
                    globalboard[cell]:setFillColor(1,1,0)
                elseif colour == "solidblue" then 
                    globalboard[cell]:setFillColor(0,0,1)
                elseif colour == "solidgreen" then 
                    globalboard[cell]:setFillColor(0,1,0)
                elseif colour == "cyan" then 
                    globalboard[cell]:setFillColor(0,1,1)
                else 
                    globalboard[cell]:setFillColor(1,1,1)
                end 
            else 
                globalboard[cell]:setFillColor(.2,.2,.2)
            end

        end
    end
end

function restoreColourPlayer(player)
    for _, pawn in ipairs(player) do
        if player.colour == "red" then
            pawn:setFillColor(1,0,0)
        elseif player.colour == "yellow" then 
            pawn:setFillColor(1,1,0)
        elseif player.colour == "blue" then
            pawn:setFillColor(0,0,1)
        elseif player.colour == "green" then
            pawn:setFillColor(0,1,0)
        end
    end
end

function playertap(event)
    --[[ print("___t", turn,"___p", table.indexOf(player, event.target))
    print("___tap", event.target.tapped, "___out", event.target.out)
    print("___Rolled: ", player.rolled) ]]
    if takePawn and player.out then 
        print("TAKEPAWN")
        restoreColourPlayer(player)
        pawnToTake = event.target
        event.target:setFillColor(.35,.2,.86)
        event.target:toFront()
    elseif turn then
        for _,pawn in ipairs(player) do
            restoreColourBoard(pawn)
        end
        event.target.tapped = true
        print("POINT A") 
        if event.target.out and player.out then
            print("POINT B: ", player.rolled, blockMessage)
            if player.rolled and not blockMessage and not (diea == 0 and dieb == 0) then
                print("--Roll info sent to server")
                possiblestr = '"possibleMoves": true,'
                pawnstr = '"pawn":' ..'"pawn' ..table.indexOf(player, event.target) .. '",'
                dicestr = '"dice":[' .. diea ..',' .. dieb.. ']'
                rollinfo = '{' .. possiblestr ..pawnstr .. dicestr .. '}'
                comms.sendMessage(rollinfo)
                blockMessage = true
                tappedpawn = event.target
            end
        end
    end
end 


function movehorizontal(player, tile)
    transition.moveTo(player, {x = tile.x, 500})
end


function finishTurn(pawn)
    comms.sendinfo(player, true)
    diea = nil 
    dieb = nil
    turnText.alpha = 0
    turn = false 
    player.rolled = true
    rolldice:setEnabled(false)
    print("-------------------------TURN FINISHES HERE-------------------------")
end


function tapListener(event)
    print(table.indexOf(globalboard, event.target))
    if turn then 
        pawn = tappedpawn
        if pawn ~= nil and pawn.tapped and pawn.validmoves ~= nil then 
            for _, cell in ipairs(pawn.validmoves) do 
                
                if globalboard[cell] == event.target then 
                    restoreColourBoard(pawn)
                    tile = globalboard[cell]
                    transition.moveTo(pawn, {y = tile.y, 500, transition=easing.inOutExpo, onComplete = movehorizontal(pawn, tile)})
                    pawn.pos = cell 
                    boardlib.enablelap(pawn)
                    pawn.tapped = false 
                    tappedpawn = nil 
                    
                    print('DD',diea, dieb,'DD')
                    if pawn.validmoves[1] == cell and (diea ~= 0 and dieb ~= 0) and (diea ~= nil and dieb~=nil) then
                        if not equaldice then 
                            print("FINISH A")
                            finishTurn(pawn)
                        else 
                            rolldice:setEnabled(true)
                            comms.sendinfo(player, false)
                        end
                        diea = 0
                        dieb = 0
                        print('ADD',diea, dieb,'ADD')
                    else
                        if pawn.validmoves[2] == cell and diea ~= 0 then 
                            diea = 0
                        else 
                            dieb = 0
                        end 

                        if diea == dieb and diea == 0 then 
                            if not equaldice then
                                print("FINISH B")
                                finishTurn(pawn)
                            else 
                                rolldice:setEnabled(true)
                                print("HERE-1")
                                comms.sendinfo(player, false)
                                equaldice = false
                            end
                        else 
                            rolldice:setEnabled(false)
                            print("HERE-2 ")
                            comms.sendinfo(player, false)
                            pawn.validmoves = nil
                            return true
                        end
                        print('ADD',diea, dieb,'ADD')
                    end
                    
                    if cell == 97 then 
                        pawn:removeSelf()
                    end
                end

            end
            pawn.validmoves = nil
        end 
    end
    return false
end



for i, pawn in ipairs(player) do
    pawn:addEventListener( "tap", playertap)
end

local function roll( event )
    if turn then
        local filename = "dice"
        local extension = ".png"
    
        if ( "ended" == event.phase ) then
            diea=math.random(1,6)
            dieb=math.random(1,6)
            local rolleda = display.newImageRect(filename..diea..extension,50,50)
            rolleda.x, rolleda.y = 50, 125
            local rolledb = display.newImageRect(filename..dieb..extension,50,50)
            rolledb.x, rolledb.y = 100, 125
        
            print("---", player.out, timesRolled)
            if player.out then
                if (diea == dieb) and (diea ~= nil) then
                    equaldice = true
                    timesRolled = timesRolled + 1
                else 
                    timesRolled = 0
                end
                player.rolled = true
                rolldice:setEnabled(false)
            else 
                if timesRolled == 2  and (diea ~= dieb)then 
                    turn = false
                    turnText.alpha = 0
                    rolldice:setEnabled(false) 
                    timesRolled = 0 
                    comms.sendinfo(player, true)
                else 
                    timesRolled = timesRolled + 1
                end
            end
 
            if ((diea == dieb) and (diea ~= nil) and (timesRolled >= 3) and (player.out)) then 
                print("TAKETHEPAWNOUT")
                takePawn = true
                selectPawn.isVisible = true
                selectPawn:setEnabled(true)
                takealert = native.showAlert( "Felicidades", "Puede elegir una de tus fichas para sacarla del juego.", { "Elegir ficha" }, closeAlert )
            end 
            if (diea == dieb and diea ~= nil and not player.out) then
                print("EXITPRISON")
                rolldice:setEnabled(true)
                timesRolled = 0
                exitprison(player)
            end
        end
    end

end
 


local function sendStartGame(event)
    if ( "ended" == event.phase ) then
        comms.sendMessage('{"start": true}')
    end
end 

local function onComplete( event )
    if ( event.action == "clicked" ) then
        local i = event.index
        if ( i == 1 ) then
            -- Do nothing; dialog will simply dismiss
        end
    end
end


function takePawnOut(event)
    if ( "ended" == event.phase ) then
        if pawnToTake ~= nil then 
            takepawnindex = table.indexOf(player, pawnToTake)
            table.remove(player, takepawnindex)
            pawnToTake:removeSelf()
            takePawn = false
            pawnToTake = false
            selectPawn.isVisible = false
            selectPawn:setEnabled(false)
            comms.sendinfo(player, true)
        end
    end
end

-- Boton creado (Tipo de Widget)
rolldice = widget.newButton(
    {
        width = 130,
        height = 20,
        defaultFile = "rollbutton.png",
        id = "rolldice",
        label = "Lanzar dados",
        labelColor = { default={ 1, 1, 1, 1 }, over={ .2, .2, .2,.2} },
        onEvent = roll,
        isEnabled = true
    }
)

startbutton = widget.newButton(
    {
        width = 65,
        height = 45,
        defaultFile = "startgame.png",
        id = "startgame",
        labelColor = { default={ 1, 1, 1, 1 }, over={ .2, .2, .2,.2} },
        onEvent = sendStartGame,
        isEnabled = true
    }
)

selectPawn = widget.newButton(
    {
        width = 160,
        height = 25,
        defaultFile = "select.png",
        label = "Seleccionar ficha",
        id = "select",
        labelColor = { default={ 1, 1, 1, 1 }, over={ .2, .2, .2,.2} },
        onEvent = takePawnOut,
        isEnabled = false, 
    }
)


selectPawn.isVisible = false
rolldice.x = 83
rolldice.y = halfH *2 -15
startbutton.x = rolldice.x + 115
startbutton.y = rolldice.y
selectPawn.x = rolldice.x  + 150
selectPawn.y = rolldice.y 
testnum = 0





----------------

local function processInfo()
    data, incoming = comms.receiveInfo()
        if incoming then
            if data ~= nil then 
                message = json.decode(data)
                if not otherplayersinfo then
                    if message.newplayer ~=nil then
                        print("NEWPLAYER")
                        newPlayerid = message.playerid 
                        newPlayer = boardlib.drawOtherPlayers(message.colour)
                        newPlayer.playerid = newPlayerid
                        newPlayer.colour = message.colour
                        table.insert(otherPlayers, newPlayer)
                        otherhomecolour = tellHomeColour(newPlayer)
                        drawInJail(newPlayer, otherhomecolour)
                    elseif message.startgame then 
                        print("START")
                        start = true 
                        otherplayersinfo = true 
                        startbutton.isVisible = false
                    elseif message.waiting then 
                        alert = native.showAlert( "Esperando", "Seguimos esperando a más jugadores.", { "OK" }, closeAlert )
                    end
                    
                elseif start then 
                    if message.transition then 
                        otherPlayers = boardlib.transitionOtherPlayers(otherPlayers, message.playerspositions, globalboard)
                    elseif message.turngranted and message.playerid == player.playerid then 
                        print(message.turngranted)
                        print("\n\n\n-------------------------TURN STARTS HERE-------------------------\n\n\n")
                        turn = true
                        turnText.alpha = 1
                        rolldice:setEnabled(true)  
                    elseif message.validmoves then 
                        print("L-511.TAPPEDPAWN: ", tappedpawn)
                        if tappedpawn ~= nil then 
                            tappedpawn.validmoves = message.validmoves
                            blockMessage = false
                            paintTiles(tappedpawn)
                        end
                    end
                    if message.jailedpawns ~= nil then 
                        if message.jailedpawns[player.playerid] ~= nil then 
                            player.out = false
                            print("GOT JAILED")
                            for _, jailedpos in ipairs(message.jailedpawns[player.playerid]) do
                                for z, pawn in ipairs(player) do 
                                    if pawn.pos == jailedpos then 
                                        pawn.out = false
                                        pawn.pos = boardlib.resetPos(player.colour)
                                        pawn.lap = false
                                        otherhome = tellHomeColour(player)
                                        pawn.x = otherhome[1]
                                        pawn.y = otherhome[2]
                                    end 
                                end
                            end 
                            
                        end
                        
                        for _, otherPlayer in ipairs(otherPlayers) do 
        
                            if message.jailedpawns[otherPlayer.playerid] ~= nil then 
                                for j, jailedpos in ipairs(message.jailedpawns[otherPlayer.playerid]) do
                                    for x, otherPawn in ipairs(otherPlayer) do 
                                        if otherPawn.pos == jailedpos then 
                                            otherPawn.pos = boardlib.resetPos(otherPlayer.colour)
                                            otherhome = tellHomeColour(otherPlayer)
                                            otherPawn.x = otherhome[1]
                                            otherPawn.y = otherhome[2]
                                        end 
                                    end
                                end
                            end
                        end

                    end
                end 
            end
        end

end

local s_loop = timer.performWithDelay(50, processInfo, -1)


--------------------------------------------------
function scene:create(event)

    local sceneGroup = self.view
        
    skypos = boardlib.toScreen({0,-70},center)
    sky = display.newCircle(skypos[1], skypos[2],30)
    sky:setFillColor(0,1,1)
    
    homegenpos = {-99,32}
    homeredpos = homegenpos
    homeredpos = boardlib.toScreen(homeredpos, center)
    homered = display.newRect(homeredpos[1], homeredpos[2], 72, 78)
    homered.x = homeredpos[1]
    homered.y = homeredpos[2]

    homegreenpos = {homegenpos[1]*-1,homegenpos[2]}
    homegreenpos = boardlib.toScreen(homegreenpos, center)
    homegreen = display.newRect(homegreenpos[1], homegreenpos[2], 72, 78)
    homegreen.x = homegreenpos[1]
    homegreen.y = homegreenpos[2]

    homegenpos = {-99,-172}
    homebluepos = {homegenpos[1],homegenpos[2]}
    homebluepos = boardlib.toScreen(homebluepos, center)
    homeblue = display.newRect(homebluepos[1], homebluepos[2], 72, 78)
    homeblue.x = homebluepos[1]
    homeblue.y = homebluepos[2]

    homegenpos = {-99,-172}
    homeyellowpos = {homegenpos[1],homegenpos[2]}
    homeyellowpos = boardlib.toScreen(homeyellowpos, center)
    homeyellow = display.newRect(homeyellowpos[1], homeyellowpos[2], 72, 78)
    homeyellow.x = homeyellowpos[1]
    homeyellow.y = homeyellowpos[2]

    homegenpos = {-99,-172}
    homebluepos = {homegenpos[1]*-1,homegenpos[2]}
    homebluepos = boardlib.toScreen(homebluepos, center)
    homeblue = display.newRect(homebluepos[1], homebluepos[2], 72, 78)
    homeblue.x = homebluepos[1]
    homeblue.y = homebluepos[2]

    homered:setFillColor(.61,0,0.59)
    homeblue:setFillColor(.61,0,0.59)
    homegreen:setFillColor(.61,0,0.59)
    homeyellow:setFillColor(.61,0,0.59)

    -- Se dibuja el tablero
    everything = display.newGroup()

    globalboard, blackies = boardlib.drawboard(everything, center)
    table.insert(globalboard, sky)
    for i, tile in ipairs(globalboard) do
        tile:addEventListener("tap", tapListener)
    end
    homecolour = tellHomeColour(player)
    drawInJail(player, homecolour)



    for i, pawn in ipairs(player) do
        pawn:toFront()
    end
    turnText = display.newText(sceneGroup, "Su turno", display.contentCenterX + 15, display.contentCenterY - 100, native.systemFont, 20 )
    turnText.alpha = 0
    sceneGroup:insert(everything)
    
end

function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
 
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene