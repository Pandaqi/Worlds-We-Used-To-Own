
Events = Object:extend()

function Events:new(time, next_event, events, season)
  self.time = time
  self.next_event = next_event
  self.events = events
  
  self.season = season
  
  if #events > 0 then
    self.windShader =  love.graphics.newShader[[
      extern number offset;
      extern number pivot;
      vec4 position( mat4 transform_projection, vec4 vertex_position )
      {
          //vertex_position.x = vertex_position.x + offset * (pivot - vertex_position.y) * 0.0625;
          vertex_position.x = vertex_position.x + offset * min((pivot - vertex_position.y) * (pivot - vertex_position.y), 1600) * 0.002;
          return transform_projection * vertex_position;
      }
    ]]
  end
end

function Events:update(dt)   
  self.time = self.time + dt
  
  -- if it exists, and the time is right, handle the next event(s)
  if self.next_event >= 0 then
    while self.time >= self.next_event do
      local r = self:handleNextEvent()
      
      if self.next_event < 0 then break end
    end
  end
end

-- insert event into SORTED list
function Events:addEvent(e)
  -- make sure interval is set relative to current time
  e[1] = self.time + e[1]
  
  -- find right position, insert it
  local insertIndex = 1
  while insertIndex <= #self.events do
    if self.events[insertIndex][1] >= e[1] then
      break
    end
    insertIndex = insertIndex + 1
  end
  
  table.insert(self.events, insertIndex, e)
  
  -- if it happens to be the first event coming up, update our next event variable
  if insertIndex == 1 then
    self.next_event = e[1]
  end
end

-- An event is set up using the following construction:
-- { _time_ , _type_ , _optional parameters depending on type_ }

function Events:handleNextEvent()
  -- get the first event, immediately remove it from the queue
  local e = table.remove(self.events, 1)
  
  -- DO SOMETHING WITH IT
  self:handleEvent(e)
  
  -- set the timer for the next event, if it exists
  if #self.events > 0 then
    self.next_event = self.events[1][1]
  else
    self.next_event = -1
  end
end

function Events:handleEvent(e)
  local t = e[2] -- the type
  
  if t == "pregnant" then
    -- stop doing it, the female becomes pregnant
    e[3].currentJob = "pregnant"
    e[4]:resetJob(nil)
    
    -- make sure the babies are born sometime in the future
    self:addEvent({ANIMAL_PROPS[e[3].class][3], "birth", e[3], e[4].DNA})
    
  elseif t == "birth" then
    -- create a birth!
    -- the male parent only has its DNA saved, as he can die during pregnancy of the female
    REGIONS[e[3].reg]:animalBirth(e[3].x, e[3].y, e[3].class, 3, e[3].owner, e[3].inside, e[3].DNA, e[4])
    e[3]:resetJob(nil)
    
  elseif t == "age" then
    -- level up that animal
    e[3]:setProperties(e[3].age + 1)
    
    -- schedule the next aging
    self:addEvent({ONE_YEAR, "age", e[3]})
  
  elseif t == "build" then
    -- only update if our animal is still working on it
    if e[5].jobID == e[3]:getID() then
      e[5]:finishedAction(t)
  
      -- increase the health of the building
      local r = e[3]:updateHealth(e[4])
      
      -- if we're not finished, plan another event
      if r then
        local checkResources, subclassTargets = e[3]:checkResources(e[5].item)
        
        -- if resources we currently have >= resources we currently need
        if checkResources then
          -- continue building
          self:addEvent({e[5].buildingSpeed, "build", e[3], 1, e[5]})
        else
          -- if not, first go and fetch the resources we need
          e[5]:setGoal({"build", e[3], subclassTargets})
        end
      else
        -- if we're finished, tell the animal to stop working
        -- and claim the region containing the building
        e[5]:resetJob(nil)
        REGIONS[e[3].region]:setOwner(e[5]:getOwner())
      end
    end
  
  elseif t == "destroy" then
    if e[3] == nil then
      return
    end
  
    -- decrease the health of some building
    if e[5].jobID == e[3]:getID() then
      local r = e[3]:updateHealth(e[4])
      
      -- if we're not finished, plan another event
      if r then
        self:addEvent({5, "destroy", e[3], -1, e[5]})
      else
        -- if we're finished, tell the animal to stop working
        -- delete the building
        -- and un-claim the region containing the building
        e[5]:resetJob(nil)
        REGIONS[e[3].region]:setOwner(0)
        e[3]:die()
      end
    end
  
  elseif t == "idlejump" then
    if e[3] == nil then
      return
    end
  
    -- if the animal is currently idle, jump! (but stay within region)
    if e[3].currentJob == "" and not e[3].hover and not e[3].selected and e[3].dest == nil then
      local myReg = REGIONS[e[3].reg]
      if myReg.visible then
        local angle, radius = math.drandom(0, 2 * math.pi), math.drandom(10,30)
        local newX, newY = e[3].x + math.cos(angle)*radius, e[3].y + math.sin(angle)*radius
          
        -- if this leads to a destination outside of target region, change it
        while not myReg:generalHitTest(newX, newY, myReg.innerPolygon) do
          angle = math.drandom(0, 2 * math.pi)
          newX, newY = e[3].x + math.cos(angle)*radius, e[3].y + math.sin(angle)*radius
        end
        
        -- move!
        e[3]:setDestination(newX, newY, myReg, {})
      end
      
      -- schedule next jump
      self:addEvent({math.randexp(IDLE_JUMP_TIME), "idlejump", e[3]})
      
    end
    
  elseif t == "nutrition" then
    if e[3] == nil then
      return
    end
    
    local r = e[3]:updateNutrition(e[4])
    
    -- if it's a decrease in nutrition
    if e[4] < 0 then
      if r == "dead" then
        return
      end
      
      -- keep decreasing!
      self:addEvent({HUNGER_TIME, "nutrition", e[3], -1})
      
      -- if we're close to dying, and not going somewhere, search for food (if we're not already doing so)
      if r and e[3].currentJob ~= "nutrition" and e[3].dest == nil then
        local obj, end_region, start_region = e[3]:searchFood()
        if obj ~= nil then
          e[3]:setFullAction(obj, end_region, start_region)
        end
      end
    else
      -- we ate something, there's a chance it will make us sick!
      e[3]:updateCondition(0)
      
      -- make sure the plant loses health, and dies if necessary
      -- also, when health is lost, the plant starts growing again
      if e[5] ~= nil then
        local r2 = e[5]:updateHealth(-1)
        if not r2 then
          e[5]:die()
        elseif not e[5].growthPlanned then
          e[5].growthPlanned = true
          self:addEvent({GROWING_TIME, "naturegrow", e[5]})
        end
      else
        -- if our plant has already died, just stop eating
        e[3]:resetJob(nil)
        return
      end
      
      -- if we're not full yet, and still near a plant, keep eating
      if r ~= "full" and e[3].currentJob == "nutrition" and e[5].health > 0 then
        self:addEvent({EATING_SPEED, "nutrition", e[3], 1, e[5]})
      else
        -- otherwise, reset our job
        e[3]:resetJob(nil)
        e[3]:finishedAction(t)
      end
    end
    
  elseif t == "pooping" then
    if e[3] == nil then
      return 
    end
    
    -- with some probability, plant something (of a certain type) in my spot
    if math.prandom(0,1) > 0.5 and not e[3].inside then
      REGIONS[e[3].reg]:addPlant(e[3].x, e[3].y, -1)
    end
    
    -- schedule new poopie
    self:addEvent({POOP_TIME, "pooping", e[3]})
    
  elseif t == "naturegrow" then
    if e[3] == nil then
      return 
    end
    
    e[3].growthPlanned = false
    
    -- our plant grows by 1
    -- if the maximum health is not yet reached, plan another growth event
    local r = e[3]:updateHealth(1)
    if r then
      e[3].growthPlanned = true
      self:addEvent({GROWING_TIME, "naturegrow", e[3]})
    end
  elseif t == "breaknature" then
    if e[3] == nil then
      return 
    end
    
    -- do all of this only if our animal is still working on it
    if e[5].jobID == e[3]:getID() then
      
      -- decrease the health of this nature object
      local r = e[3]:updateHealth(e[4])
      
      -- plan for growth!
      if not e[3].growthPlanned then
        e[3].growthPlanned = true
        self:addEvent({GROWING_TIME, "naturegrow", e[3]})
      end
      
      -- if we're not finished, plan another event
      if r then
        self:addEvent({5, "breaknature", e[3], -1, e[5]})
      else
        -- if we're finished, tell the animal to stop working
        e[5]:resetJob(nil)
      end
      
      e[5]:finishedAction(t)
    end
  
  elseif t == "chat" then
    -- if one of them is ill, they might infect the other
    if e[3].illness > 0 then
      e[4]:updateCondition(0)
    end
    
    if e[4].illness > 0 then
      e[3]:updateCondition(0)
    end
  
    -- we're finished chatting
    if e[3].currentJob == "chat" then
      e[3]:resetJob()
    end
    
    if e[4].currentJob == "chat" then
      e[4]:resetJob()
    end
  
  elseif t == "condition" then
    local r = false
    
    if math.prandom(0,1) >= e[3].illnessResistance then
      -- make the animal even more sick
      r = e[3]:updateCondition(1)
    else
      -- make the animal better
      r = e[3]:updateCondition(-1)
    end
  elseif t == "seasonchange" then
    -- go to next season (0 = spring, 1 = summer, 2 = autumn, 3 = winter)
    self.season = self.season + 1
    if self.season > 3 then
      self.season = self.season - 4
    end
    
    self:broadcastSignal()

    -- plan the next season change
    self:addEvent({ONE_YEAR * 0.25, "seasonchange"})
  end
end

function Events:clean()
  self.windShader = nil
  
  -- go through all events
  for i,e in ipairs(self.events) do
    for j=3,#e do
      -- if we've found something that SHOULD be a unit/home
      if type(e[j]) == "table" and type(e[j]["getClass"]) == "function" and e[j]:getClass() ~= nil then
        -- replace it with its ID and region
        e[j] = {e[j]:getID(), e[j]:getRegion()}
      end
    end
  end
end

function Events:unclean()
  -- go through all events
  local i = 1
  while i <= #self.events do
    local e = self.events[i]
    print_r(e)
    for j=3,#e do
      -- if we've found something that SHOULD be a unit
      if e[j] ~= nil and type(e[j]) == "table" and e[j][1] ~= nil and e[j][2] ~= nil then
        -- replace it with its actual object
        e[j] = REGIONS[e[j][2]]:getNatureWithID(e[j][1])
        
        -- if the object doesn't exist anymore, the event is meaningless and should be removed
        if e[j] == nil then
          table.remove(self.events, i)
          
          if i == 1 then
            self.next_event = self.events[1][1]
          end
          
          i = i - 1
        end
      end
    end
    
    i = i + 1
  end
end

function Events:removeObjectFromEvents(o)  
  local i = 1
  -- go through all events
  while i <= #self.events do
    local e = self.events[i]
    
    local countTables = 0
    local found = false
    for j=3,#e do
      -- if we find our object, remove the reference
      if type(e[j]) == "table" then
        if e[j]:getID() == o:getID() then
          e[j] = nil
          found = true
        end
        countTables = countTables + 1
      end
    end
    
    -- if our event now has length 2, it means the whole event can be removed
    if (found and countTables == 1) or #e <= 2 then
      table.remove(self.events, i)
      
      if i == 1 then
        self.next_event = self.events[1][1]
      end
      
      i = i - 1
    end
    
    i = i + 1
  end
end  

function Events:getSeason()
  return self.season
end

function Events:broadcastSignal()
  -- go through all regions
  local nR = #REGIONS
  for i=1,nR do
    local r = REGIONS[i]
    
    -- if it gets WINTER
    if self.season == 3 then
      -- add some extra weather conditions
      if math.prandom(0,1) > 0.25 then
        r.weatherStatus = 2
      end
      
      if r.weatherStatus > 0 then 
        r.weatherStatus = 2
      end
      
    -- if it gets SPRING or AUTUMN
    elseif self.season == 0 or self.season == 2 then
    
      if r.weatherStatus > 0 then
        if math.prandom(0,1) > 0.75 then
          r.weatherStatus = 3
        else
          r.weatherStatus = 1
        end
      end
      
    -- if it gets SUMMER
    elseif self.season == 1 then
      if r.weatherStatus > 0 then
        -- remove some weather conditions
        if math.prandom(0,1) > 0.5 then
          r.weatherStatus = 0
        else
          r.weatherStatus = 1
        end
      end
    end
    
    -- go through all nature
    local N = r.nature
    local nN = #N
    for j=1,nN do
      local n = N[j]
      if n:isNature() then
        self:addEvent({math.randexp(ONE_YEAR * 0.25 * 0.1), "changelook", n})
      end
    end
  end
end