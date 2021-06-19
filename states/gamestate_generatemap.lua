function GAME_STATES.generateMapInit()
  -- create a second thread for map generation
  generationThread = love.thread.newThread("tools/generation_thread.lua")
	generationChannel = love.thread.getChannel("mapGenerator")
  -- generationChannel:push(any user defined settings in a flat table)
	generationThread:start()
  
  loaderRadius = 50
  counter = 1
end

function GAME_STATES.generateMap(dt)  
  -- gets the latest message from the channel
  m = generationChannel:pop() 
  
  -- if the counter should be updated, we've reached another generation stage
  if m == "update counter" then
    counter = counter + 1
  -- if the channel is done, start the game!
  elseif m == "all done" then
    switchGameState("mainGame")
  end
  
  -- get any errors from the thread
  if generationThread:getError() then
    print(generationThread:getError())
  end
  
  -- increase size of circle
  loaderRadius = loaderRadius + dt
end

function GAME_STATES.generateMapDraw()
  love.graphics.printf("Generating Map - Pass " .. counter, 0, love.graphics.getHeight()*0.5-6, love.graphics.getWidth(), 'center')
  love.graphics.circle('line', love.graphics.getWidth()*0.5, love.graphics.getHeight()*0.5, loaderRadius)
end