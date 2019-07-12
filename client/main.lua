local composer = require( "composer" )
comms = require "communication"
json = require ("json")
playerid = ""
availablecolours = {}
otherPlayers = {}
serverAddress = ""
time = os.date('*t')

red = {1,0,0}
yellow = {1,1,0}
blue = {0,0,1}
green = {0,1,0}
selectedTileColour = {.35,.2,.86}
gray = {.2,.2,.2}
black = {0,0,0}
colourForHome = {.61,0,0}
white = {.9,.9,.9}
cyan = {0,1,1}
-- Hide status bar
display.setStatusBar( display.HiddenStatusBar )
 
-- Seed the random number generator
math.randomseed( os.time() )
 
-- Go to the menu screen
composer.gotoScene( "menu" )
