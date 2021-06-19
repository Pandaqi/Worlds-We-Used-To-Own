
GUI = Object:extend()

function GUI:new()
  self.bounds = {}
  self.activated = false
  self.cur_type = 0 -- 0 = nothing, 1 = region, 2 = unit
  self.cur_obj = nil
  self.setup = false
  
  -- for display and alignment purposes
  self.table = {}
  self.font = { file = love.graphics.newFont("fonts/PrimerBold.ttf", 18), size = 18 }
  self.cur_hover = nil
end

-- called whenever we select a (new) region
function GUI:loadRegion(r)
  self.activated = true
  self.cur_type = 1
  self.cur_obj = r
  self.buttons = {}
  self.cur_hover = nil
  self.setup = true
end

-- similarly, called whenever we select a (new) unit
function GUI:loadUnit(r)
  -- if we have multiple units selected, add this one
  if self.activated and self.cur_type == 2 then
    self.multipleUnits = true
    table.insert(self.cur_obj, r)
  else
    self.multipleUnits = false
    
    self.activated = true
    self.cur_type = 2
    self.cur_obj = r
  end
  self.buttons = {}
  self.cur_hover = nil
  self.setup = true
end

-- called whenever we deselect something
function GUI:unload()
  self.activated = false
  self.buttons = {}
end

-- Called by camera, refreshes the GUI and positioning of things
function GUI:updateBounds(windowWidth, windowHeight)
  self.bounds = { x = 0, y = 0, width = windowWidth, height = 100 }
end

function GUI:updateButtons()
  self.setup = true
  self.cur_hover = nil
  self.buttons = {}
end

function GUI:hitTestBounds(x, y)
  if not self.activated or (x < self.bounds.x or (self.bounds.x + self.bounds.width) < x or y < self.bounds.y or (self.bounds.y + self.bounds.height) < y) then
    return false
  end
  return true
end

-- Actually draws the GUI, called from main update loop
function GUI:draw()
  -- display FPS, to check performance while programming
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS()), self.bounds.width-200, 200)
  
  love.graphics.print("Time: " .. tostring(EVENTS.time), self.bounds.width-200, 370)
  love.graphics.print("Events: " .. tostring(#EVENTS.events), self.bounds.width-200, 400)
  
  love.graphics.print("Season: " .. tostring(EVENTS:getSeason()), self.bounds.width - 200, 430)
  
  if not self.activated then
    return
  end
  
  love.graphics.setFont(self.font.file)
  
  local b = self.bounds
  local o = self.cur_obj
  
  love.graphics.setColor(50, 50, 50, 150)
  love.graphics.rectangle('fill', b.x, b.y, b.width, b.height)
  
  love.graphics.setColor(240, 240, 240, 255)
  -- REGION
  if self.cur_type == 1 then
    GUI:startTable()
    
    GUI:startColumn(0.2, 3)
    self:createColouredText("Terrain", o:getTerrain(), "terrain")
    self:createBar("Fertility", o:getFertility())
    self:createBar("Connections", #o:getConnections())
    GUI:endColumn()
    
    GUI:startColumn(0.2, 3)
    self:createColouredText("Owner", o:getOwner(), "player")
    self:createBar("Trees", o:getTrees())
    self:createBar("Animals", o:getAnimals())
    GUI:endColumn()
    
    GUI:startColumn(0.2, 3)
    local bui = o:getBuilding()
    self:createColouredText("Building", bui, "building")
    if bui == nil then
      if o:getPresence()[1] > 0 then
        self:createButton("BUILD", "build", 1)
      end
    end
    GUI:endColumn()
    
  -- ANIMAL
  elseif self.cur_type == 2 then
    if self.multipleUnits then
      GUI:startTable()
      
      GUI:startColumn(0.2, 3)
      self:createColouredText("Class", self:getAggregate(o, "class", false, false), "class")
      self:createBar("Health", self:getAggregate(o, "health", true, false))
      self:createBar("Age", self:getAggregate(o, "age", true, false))
      GUI:endColumn() 
      
      GUI:startColumn(0.2, 3)
      self:createColouredText("Owner", self:getAggregate(o, "owner", false, false), "player")
      self:createColouredText("Gender", self:getAggregate(o, "gender", false, false), "gender")
      self:createColouredText("Specialty", self:getAggregate(o, "specialty", false, false), "specialty")
      GUI:endColumn()
      
      GUI:startColumn(0.3, 3)
      self:createColouredText("Activity", self:getAggregate(o, "getActivity", false, true), "activity")
      self:createBar("Nutrition", self:getAggregate(o, "nutrition", true, false))
      GUI:endColumn()
      
      GUI:startColumn(0.3, 3)
      self:createText("Multiple units selected")
      GUI:endColumn()
      
    else
      GUI:startTable()
      
      GUI:startColumn(0.2, 3)
      self:createColouredText("Class", o:getClass(), "class")
      self:createBar("Health", o:getHealth())
      self:createBar("Age", o:getAge())
      GUI:endColumn() 
      
      GUI:startColumn(0.2, 3)
      self:createColouredText("Owner", o:getOwner(), "player")
      self:createColouredText("Gender", o:getGender(), "gender")
      self:createColouredText("Specialty", o:getSpecialty(), "specialty")
      GUI:endColumn()
      
      GUI:startColumn(0.3, 3)
      self:createColouredText("Activity", o:getActivity(), "activity")
      self:createBar("Nutrition", o:getNutrition())
      self:createColouredText("Condition", o:getCondition(), "condition")
      GUI:endColumn()
      
      if o:getItem() ~= nil then
        GUI:startColumn(0.3, 3)
        self:createColouredText("Item", o:getItem(), "item")
        self:createButton("USE", "useitem", 2)
        self:createButton("DROP", "dropitem", 3)
        GUI:endColumn()
      end
    end
  end
  
  self.setup = false
end

function GUI:getAggregate(arr, what, isNum, isFunction)  
  local result = arr[1][what]
  
  if isFunction then
    if what == "getActivity" then
      result = arr[1]:getActivity()
    end
  end
  
  for i=2,#arr do
    local newRes = arr[i][what]
    if isFunction then
      if what == "getActivity" then
        newRes = arr[i]:getActivity()
      end
    end
    
    if result ~= newRes then
      if isNum then
        return 0
      else
        return "MIXED"
      end
    end
  end
  
  return result
end

function GUI:startTable()
  self.table = {}
  self.table.paddingX = 15
  self.table.paddingY = 15
  
  self.table.x = self.bounds.x
  self.table.y = self.bounds.y
  
  self.table.width = 0
  self.table.height = 0
end

function GUI:endColumn()
  self.table.x = self.table.x + self.table.paddingX
end

function GUI:startColumn(w, r)
    -- set x position to new column, reset y position to top
  self.table.x = self.table.x + self.table.width + self.table.paddingX
  self.table.y = self.bounds.y + self.table.paddingY
  
  -- set column width, in *percentages* of total GUI width
  self.table.width = w * (self.bounds.width) - self.table.paddingX * 2
  
  -- set height of each row, in *percentages* of total GUI height, using r = amount rows
  self.table.rowHeight = (1 / r) * (self.bounds.height - self.table.paddingY * 2)
end

function GUI:createText(text)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(text, self.table.x, self.table.y)
  
  self.table.y = self.table.y + self.table.rowHeight
end

function GUI:createColouredText(title, text, text_type)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(title .. ": ", self.table.x, self.table.y)
  
  if text_type == "terrain" then
    love.graphics.setColor(TERRAIN_COLOUR_MAP[text]:getLight())
    if text <= 3 then
      text = "WATER"
    elseif text <= 6 then
      text = "GRASS"
    else
      text = "MOUNTAIN"
    end
  elseif text_type == "player" then
    if text < 1 then
      love.graphics.setColor(255, 255, 255)
      text = "UNOWNED"
    else
      love.graphics.setColor(COLOUR_MAP[text]:getVeryLight())
      text = "PLAYER " .. text
    end
  elseif text_type == "class" then
    love.graphics.setColor(ANIMAL_COLOUR_MAP[text]:getVeryLight())
    text = ANIMAL_NAME_MAP[text]
  elseif text_type == "building" then
    love.graphics.setColor(255, 255, 255)
    if text == nil then
      text = "NONE"
    else
      text = text:getName()
    end
  elseif text_type == "gender" then
    if text == true then
      love.graphics.setColor(230, 150, 150)
      text = "FEMALE"
    elseif text == false then
      love.graphics.setColor(150, 150, 230)
      text = "MALE"
    end
  elseif text_type == 'activity' then
    love.graphics.setColor(255, 255, 255)
    if text == "" then
      text = "idle"
    end
  elseif text_type == "specialty" then
    love.graphics.setColor(255, 255, 255)
  elseif text_type == "condition" then
    if text == 0 then 
      love.graphics.setColor(100, 255, 100)
      text = "HEALTHY"
    elseif text == 1 then
      love.graphics.setColor(140, 215, 140)
      text = "ILL"
    elseif text == 2 then
      love.graphics.setColor(180, 170, 180)
      text = "VERY ILL"
    else
      love.graphics.setColor(240, 100, 100)
      text = "EXTREMELY ILL"
    end
  end
  love.graphics.printf(text, self.table.x, self.table.y, self.table.width, 'right')
  
  self.table.y = self.table.y + self.table.rowHeight
end

function GUI:createBar(title, value)
  love.graphics.setColor(255, 255, 255, 50)
  for i=1,10 do
    love.graphics.rectangle('fill', self.table.x + self.table.width - i * 11, self.table.y + 2, 10, self.font.size+2)
  end
  
  love.graphics.setColor(255, 255, 255)
  for i=1,math.round(value) do
    love.graphics.rectangle('fill', self.table.x + self.table.width - i * 11, self.table.y + 2, 10, self.font.size+2)
  end
  love.graphics.print(title .. ": ", self.table.x, self.table.y)
  self.table.y = self.table.y + self.table.rowHeight -- is arbitrary padding for now
end

-- -- -- -- -- -- -- -- -- --[[
-- BUTTONS
-- -- -- -- -- -- -- -- -- --]]
function GUI:createButton(title, action, id)
  -- actually display the button (check for hover)
  if self.cur_hover ~= nil and self.buttons[self.cur_hover].id == id then
    love.graphics.setColor(220, 220, 220, 255)
  else
    love.graphics.setColor(180, 180, 180, 255)
  end
  
  love.graphics.rectangle('fill', self.table.x, self.table.y, self.table.width, self.table.rowHeight)
  
  love.graphics.setColor(255, 255, 255)
  love.graphics.printf(title, self.table.x, self.table.y, self.table.width, 'center')
  
  -- add it to buttons list, if not already there
  if self.setup then
    table.insert(self.buttons, {x1 = self.table.x, x2 = self.table.x+self.table.width, y1 = self.table.y, y2 = self.table.y + self.table.rowHeight, action = action, id = id})
  end
  
  self.table.y = self.table.y + self.table.rowHeight
end

function GUI:hitTestButton(b, x, y)
  if (x < b.x1 or b.x2 < x or y < b.y1 or b.y2 < y) then
    return false
  end
  return true
end

function GUI:performAction(what)
  local o = self.cur_obj
  if what == "build" then
    -- build something
    o:addBuilding("home", 1)
  elseif what == "useitem" then
    o:useItem()
  elseif what == "dropitem" then
    o:dropItem()
  end
end

function GUI:handleHover(X, Y)
  -- check if user hovers over any button (simple AABB hittesting)
  local result = false
  for i,b in pairs(self.buttons) do
    result = self:hitTestButton(b, X, Y)
    if result then
      self.cur_hover = i
      break
    end
  end
  
  if not result then 
    self.cur_hover = nil 
  end
end

function GUI:handleClick()
  if self.cur_hover ~= nil then
    GUI:performAction(self.buttons[self.cur_hover].action)
  end
end