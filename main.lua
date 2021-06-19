GAME_STATES = {}
CURRENT_STATE = nil

function love.load()
  -- load classic library
  Object = require "tools/classic"
  require "tools/color"
  
  require "global_dictionaries"
  require "tools/extra_math"
  
  -- some other graphical thingies
  love.graphics.setBackgroundColor(0, 0, 0)
  
  require "states/gamestate_mainmenu"
  require "states/gamestate_generatemap"
  require "states/gamestate_maingame"
  require "states/gamestate_gameover"

  if love.filesystem.exists("savegame") then
    print("Savefile exists, loading from it")
    switchGameState("mainGame")
  else
    print("Savefile doesn't exist, generating map and saving it now")
    switchGameState("generateMap")
  end
end

function love.update(dt)
  GAME_STATES[CURRENT_STATE](dt)
end

function love.draw()
  GAME_STATES[CURRENT_STATE..tostring("Draw")]()
end

function switchGameState(newState)
  CURRENT_STATE = newState
  if GAME_STATES[CURRENT_STATE..tostring("Init")] ~= nil then
    GAME_STATES[CURRENT_STATE..tostring("Init")]()
  end
end

function love.keypressed(key, scancode, isRepeat)
  if GAME_STATES[CURRENT_STATE..tostring("Keypressed")] ~= nil then
    GAME_STATES[CURRENT_STATE..tostring("Keypressed")](key, scancode, isRepeat)
  end
end

function love.mousepressed(x, y, button, istouch)
  if GAME_STATES[CURRENT_STATE..tostring("Mousepressed")] ~= nil then
    GAME_STATES[CURRENT_STATE..tostring("Mousepressed")](x, y, button, isTouch)
  end
end

function love.mousereleased(x, y, button, istouch)
  if GAME_STATES[CURRENT_STATE..tostring("Mousereleased")] ~= nil then
    GAME_STATES[CURRENT_STATE..tostring("Mousereleased")](x, y, button, isTouch)
  end
end