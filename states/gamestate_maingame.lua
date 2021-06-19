function GAME_STATES.mainGameInit()
  math.randomseed(os.time())
  
  -- load map from file
  local temp_regions, temp_players, map_data, camera_data, temp_events = unpack(love.filesystem.load('savegame')())

  PREV_UNIT = { nil }
  CUR_UNIT = { nil }
  
  HOVER_UNIT = nil
  HOVER_REGION = nil
  HOVER_INSIDE = false
  HOVER_GUI = false
  
  SEL_START = nil
  
  ID = 0
  
  TIME = temp_time
  
  -- serialization throws out all the functions
  -- so, we need to reinstantiate objects to get all functionality back
  -- and simply set the parameters from the save file
  require "region"
  require "animal"
  require "animals/corpse"
  require "animals/bunny"
  
  require "nature"
  require "nature/tree"
  require "nature/stone"
  require "nature/bush"
  require "nature/plant"
  require "nature/item"
  require "nature/particle"
  
  require "buildings/home"
  REGIONS = {}
  for i,r in pairs(temp_regions) do
    table.insert(REGIONS, Region(i, r.polygon, r.centroid) )
    local new_r = REGIONS[i]
    new_r:setTerrain(r.terrain)
    new_r:setOwner(r.owner)
    new_r:setConnections(r.conn)
    new_r:setFog(r.fog, r.fogOwners, r.fogValues)
    new_r:setTrees(r.trees)
    new_r:setAnimals(r.animals)
    new_r:setPresence(r.playerPresence)
    new_r:setShoreLines(r.shoreLines)
    new_r:setMountainLines(r.mountainLines)
    new_r:setGroundLines(r.groundLines)
    new_r:setConnLines(r.connLines)
    new_r:setRiverLines(r.riverLines)
    
    new_r:setBoundingBox(r.box)
    new_r:setInnerPolygon(r.innerPolygon)
    new_r:setLocations(r.freeLocations, r.forbiddenLocations)
    
    new_r:setWeatherStatus(r.weatherStatus)
    
    local temp_id = new_r:setNature(r.nature)
    if temp_id > ID then
      ID = temp_id
    end
  end
  
  for i,r in pairs(REGIONS) do   
    r:initializeNature()
  end
  
  -- loading the players
  PLAYERS = {}
  require "player"
  for i,p in pairs(temp_players) do
    table.insert(PLAYERS, Player(i, p.class, p.friendList))
    PLAYERS[i]:setRegions(p.regions)
  end

  AMOUNT_PLAYERS = #PLAYERS
  ANIMALS = {}
  
  -- create GUI
  require "GUI"
  GUI = GUI()
  
  -- create camera
  require "camera"
  CAMERA = Camera(camera_data[1], camera_data[2], camera_data[3], 7, map_data)
  
  -- create event set, restore truncated events with their actual objects
  require "events"
  EVENTS = Events(temp_events.time, temp_events.next_event, temp_events.events, temp_events.season)
  EVENTS:unclean()
  
end

function GAME_STATES.mainGame(dt)
  EVENTS:update(dt)
  
  local camera_change = CAMERA:detectInput()
  local mouse_checked = false
  
  -- check if we're hovering over the GUI
  if GUI:hitTestBounds(love.mouse.getPosition()) then
    mouse_checked = true
    if HOVER_UNIT ~= nil then HOVER_UNIT:unHover() end
    GUI:handleHover(love.mouse.getPosition())
    HOVER_GUI = true
  else
    HOVER_GUI = false
  end
  
  for i=1,#REGIONS do
    local r = REGIONS[i]
    -- only re-check visibility if view actually changed
    if camera_change then
      r:checkVisibility(CAMERA:getBoundingBox())
    end
    
    r:update(dt)
    
    -- check for hovering over regions
    if not mouse_checked then
      local mX, mY = CAMERA:getMousePosition()
      local result = r:hitTest(mX, mY)
      if result then
        HOVER_REGION = r
        
        -- check for hovering over an object within this region
        local resultNature = r:hitTestNature(mX, mY)
        
        if resultNature == nil then
          if HOVER_UNIT ~= nil and HOVER_UNIT ~= r then HOVER_UNIT:unHover() end
          
          HOVER_UNIT = r
          
          if r:generalHitTest(mX, mY, r.innerPolygon) then
            HOVER_INSIDE = true
          else
            HOVER_INSIDE = false
          end
          
          r:doHover()
        else 
          if HOVER_UNIT ~= nil and HOVER_UNIT ~= resultNature then HOVER_UNIT:unHover() end
          
          HOVER_UNIT = resultNature
          resultNature:doHover()
        end
        mouse_checked = true
      end
    end
  end
end

local function lightStencil()
  CAMERA:lightStencil()
end

function GAME_STATES.mainGameDraw()
  CAMERA:set()
  
  -- draw all the regions
  local nR = #REGIONS
  for i=1,nR do
    REGIONS[i]:draw()
  end
  
  -- draw shadows
  for i=1,nR do
    REGIONS[i]:drawShadow()
  end
  
  -- draw the animals and nature
  for i=1,nR do
    REGIONS[i]:drawNature()
  end
  
  -- draw extra effect for selected unit
  if CUR_UNIT ~= nil then
    for i=1,#CUR_UNIT do
      local cU = CUR_UNIT[i]
      if cU ~= nil then 
        if cU.health > 0 then
          CUR_UNIT[i]:specialDraw()
        else
          CUR_UNIT[i]:deselectAction()
          CUR_UNIT[i] = nil
        end
      end
    end
  end
  
  -- if mouse is being held down, display selection rectangle
  if love.mouse.isDown(1) then
    local o = CAMERA:getMousePositionObject(love.mouse.getPosition())
    love.graphics.setColor(255, 255, 255)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', SEL_START.x, SEL_START.y, o.x - SEL_START.x, o.y - SEL_START.y)
  end 
  
  CAMERA:unset()
  
  -- ANYTHING BELOW HERE IS FIXED TO CAMERA
  -- POST-PROCESSING EFFECTS (day/night, seasonal light)
  local dayLength = 100
  local timeConverted = EVENTS.time % dayLength
  local lightValue = math.sin(timeConverted / dayLength * 2 * math.pi) * 255 * 0.5 + 255 * 0.5
  local extraLight = {50 - math.abs(lightValue - 125) / 125 * 50, 0, math.abs(lightValue - 125) / 125 * 50}
  
  -- in summer, add some yellow to the mix!
  if EVENTS:getSeason() == 1 then
    extraLight[2] = 50 - math.abs(lightValue - 125) / 125 * 50
  end
  
  love.graphics.setBlendMode("multiply")
  love.graphics.setColor(lightValue + 50 + extraLight[1], lightValue + 50 + extraLight[2], lightValue + 50 + extraLight[3])
  love.graphics.rectangle('fill', 0, 0, CAMERA.windowBounds.width, CAMERA.windowBounds.height)
  
  love.graphics.setBlendMode("lighten", "premultiplied")
  love.graphics.stencil(lightStencil, "replace", 1)
  love.graphics.setStencilTest("less", 1)
  
  love.graphics.setBlendMode("multiply", "alphamultiply")
  love.graphics.setColor(lightValue + extraLight[1], lightValue + extraLight[2], lightValue + extraLight[3])
  love.graphics.rectangle('fill', 0, 0, CAMERA.windowBounds.width, CAMERA.windowBounds.height)
  
  love.graphics.setStencilTest()
  love.graphics.setBlendMode("alpha")
  
  -- GUI
  GUI:draw()
  
end

-- For creating selection boxes
function GAME_STATES.mainGameMousepressed(x, y, button, isTouch)
  SEL_START = CAMERA:getMousePositionObject(x, y)
end

-- For when the mouse is actually released (and something clicked)
function GAME_STATES.mainGameMousereleased(x, y, button, isTouch) 
  
  -- check if we pressed something in the GUI
  if HOVER_GUI then
    GUI:handleClick()
    return
  end
  
  -- LEFT CLICK
  if button == 1 then
    -- deactivate a previous unit, if it exists
    if PREV_UNIT[1] ~= nil then
      for i=1,#PREV_UNIT do
        PREV_UNIT[i]:deselectAction()
      end
      PREV_UNIT = { PREV_UNIT[1] }
    end
    
    -- we've created a selection rectangle, select all units inside (that are ours)
    local o = CAMERA:getMousePositionObject(love.mouse.getPosition())
    if math.abs(SEL_START.x - o.x) > 10 and math.abs(SEL_START.y - o.y) > 10 then
      local b = {x1 = math.min(SEL_START.x, o.x), y1 = math.min(SEL_START.y, o.y), x2 = math.max(o.x,SEL_START.x), y2 = math.max(o.y,SEL_START.y)}
      
      CUR_UNIT = {}
      PREV_UNIT = {}
      for i,r in pairs(REGIONS) do
        if r:getVisibility() then
          for i,a in pairs(r.nature) do
            if a.class > 0 and a:getOwner() == 1 and a:checkWithinSelection(b) and a.inside == r.viewInside then
              table.insert(CUR_UNIT, a)
              table.insert(PREV_UNIT, a)
              a:selectAction()
            end
          end
        end
      end
      
      if #CUR_UNIT < 1 then 
        CUR_UNIT = { nil }
        PREV_UNIT = { nil } 
      end
      
      SEL_START = nil
      return
    end

    -- find unit we've clicked; in fact, we already know from the update function
    CUR_UNIT = { HOVER_UNIT }

    -- generate a mouse click on the unit, but only if it wasn't already selected
    if PREV_UNIT[1] ~= CUR_UNIT[1] then
      PREV_UNIT[1] = CUR_UNIT[1]
      CUR_UNIT[1]:selectAction()
    else 
      CUR_UNIT = { nil }
      PREV_UNIT = { nil }
    end
  
  -- RIGHT CLICK 
  elseif button == 2 then
    -- If our selection is a region, right-mouse click doesn't do anything
    if CUR_UNIT[1] == nil or CUR_UNIT[1]:getClass() == "region" or CUR_UNIT[1]:getClass() < 1 then
      return
    end
  
    -- move unit(s) to the clicked position (position them in a circle if there are multiple)
    -- use pathfinding (with centroids of regions), and pass that to the animal as well
    local nrUnit = #CUR_UNIT
    local X, Y = CAMERA:getMousePosition()
    local radius, angle = nrUnit*1.5, 0
    
    if nrUnit == 1 then
      radius = 0
    end
    
    for i,u in pairs(CUR_UNIT) do
      if u:getOwner() == 1 then
        -- set destination and path leading there
        local newX, newY = X + math.cos(angle)*radius, Y + math.sin(angle)*radius
        
        -- if this leads to a destination outside of target region, change it
        if not HOVER_REGION:generalHitTest(newX, newY, HOVER_REGION.polygon) then
          newX, newY = X + math.cos(angle + math.pi)*radius, Y + math.sin(angle + math.pi)*radius
        end
        
        u:setDestination(newX, newY, HOVER_REGION, REGIONS[u.reg]:pathFind(HOVER_REGION, newX, newY, u.x, u.y))
        u:resetGoal()
        
        -- set what to do on arrival
        u:setArrivalAction(HOVER_UNIT)
      end
      angle = angle + 2 * math.pi / nrUnit
    end
  end
end

-- when the user resizes the window, the camera makes sure to adjust itself and everything in the game world properly
function love.resize()
  if CAMERA ~= nil then
    CAMERA:updateBounds()
  end
end

-- when the user actually closes the window, this function is called and the game saved
function love.quit()
  if REGIONS == nil then
    return
  end
  
  GAME_STATES.saveGame()
end

-- For saving the game
-- We basically serialize all important objects and put them in a file together (in the correct order)
-- But, to save a lot of performance and disk space, we clean objects of unnecessary properties first
-- (LEFT OUT FOR NOW) But, because objects are copied by reference and not value, we first need to duplicate the damn thing
function GAME_STATES.saveGame()
  
  for i,r in pairs(REGIONS) do
    r:clean()
    for i,a in pairs(r.nature) do
      a:clean()
    end
  end
  
  EVENTS:clean()
  
  local serialize = require 'tools/ser'
  love.filesystem.write('savegame', serialize({REGIONS, PLAYERS, CAMERA:getMapData(), CAMERA:getSaveData(), EVENTS}))
end