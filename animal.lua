
Animal = Object:extend()

function Animal:new(id, owner, gender, age, x, y, scale, health, illness, region, modifier, inside, nutrition, DNA)
  self.id = id
  self.owner = owner
  
  -- properties
  self.gender = gender
  self.age = age
  self.health = health
  self.illness = illness
  self.nutrition = nutrition
  self.DNA = DNA
  
  -- for jobs/activities
  self.currentJob = ""
  self.jobID = -1
  self.item = nil
  self.trackers = {}
  self.tracking = false
  self.updateTracking = false
  self.myGoal = nil
  
  self.attackCountdown = 0
  self.frontLegAnim = 0
  self.headAnim = 0
  
  -- for efficiency/visualization
  self.visible = true
  self.changed = false
  self.hover = false
  self.alpha = 255
  
  -- position and scale
  self.x = x
  self.y = y
  self.scale = scale
  
  -- for moving to destinations
  self.dir = 1
  self.dest = nil
  self.speed = 0
  self.terrainModifier = modifier
  self.totalDest = nil
  self.dest = nil
  self.arrivalAction = nil
  self.inside = inside
  
  self.arrivalActionObject = nil
  
  -- for animations
  self.idleAnim = 0
  self.idleAnimDir = -1
  self.jumpAnim = 0
  self.jumpAnimDir = 1
  
  -- quick reference
  self.reg = region
  
  -- increment global ID counter
  ID = ID + 1
  
  -- animal/individual specific stuff
  self:establishSpecialty()
  self:setProperties(age)
end

function Animal:startEvents()
  EVENTS:addEvent({ONE_YEAR, "age", self})
  EVENTS:addEvent({HUNGER_TIME, "nutrition", self, -1})
  EVENTS:addEvent({POOP_TIME, "pooping", self})
  EVENTS:addEvent({math.randexp(IDLE_JUMP_TIME), "idlejump", self})
end

function Animal:updateCondition(dc)
  -- first contact with illness (only does something if we're not already ill)
  if dc == 0 then
    if self.illness == 0 then
      if math.prandom(0,1) >= self.illnessResistance then
        self.illness = 1
      end
    else
      return
    end
  end
  
  -- if no change is set, it can go either way
  if dc == nil then dc = math.rsign() end
  
  -- update our illness
  self.illness = self.illness + dc
  
  self:setProperties(self.age)
  
  if self.illness >= 4 then
    self:die()
    return true
  elseif self.illness <= 0 then
    return true
  end
  
  -- schedule next event
  EVENTS:addEvent({math.randexp(ILLNESS_DURATION), "condition", self})
end

function Animal:getNutrition()
  return self.nutrition
end

function Animal:updateNutrition(dn)
  self.nutrition = self.nutrition + dn
  
  if dn < 0 then
    self:updateHealth(self.recoverySpeed)
  end
  
  -- check if we're dead, in need of food, or full
  if self.nutrition <= 0 then
    self:die()
    return "dead"
  elseif self.nutrition < 5 then
    return true
  elseif self.nutrition >= 10 then
    self.nutrition = 10
    return "full"
  end
  
  return false
end

function Animal:searchFood()

  local r = REGIONS[self.reg]
  -- go through nature in this region
  for i,n in pairs(r.nature) do
    -- if we find something edible, go there, plan action on arrival
    if n.class == -1 then
      return n, r, r
    end
  end
  
  if self.nutrition <= 4 then
    -- if we can't find something edible, search in neighbour regions that we own or are unowned
    for i=1,#r.conn do
      local nei = REGIONS[r.conn[i]]
      if nei.owner == self.owner or nei.owner == 0 then
        for i,n in pairs(nei.nature) do
          if n.class == -1 then
            return n, nei, r
          end
        end
      end
    end
  end
  
end

function Animal:searchItem(startingRegion, targets)
  
  local r = REGIONS[startingRegion]
  local saveIt = nil

  -- go through nature in this region
  for i,n in pairs(r.nature) do
    -- if we find the right item, go there, plan action on arrival
    if n.class == -2 and n:hasResource(targets) ~= false then
      return n, r, REGIONS[self.reg]
    elseif saveIt == nil and n.class < -2 and n:hasResource(targets) ~= false then
      saveIt = {n, r, REGIONS[self.reg]}
    end
  end
  
  -- if we can't find something, search in neighbour regions that we own or that are unowned
  for i=1,#r.conn do
    local nei = REGIONS[r.conn[i]]
    if nei.owner == self.owner or nei.owner == 0 then
      for i,n in pairs(nei.nature) do
        if n.class == -2 and n:hasResource(targets) ~= false then
          return n, nei, REGIONS[self.reg]
        elseif saveIt == nil and n.class < -2 and n:hasResource(targets) ~= false then
          saveIt = {n, nei, REGIONS[self.reg]}
        end
      end
    end
  end
  
  if saveIt == nil then return nil end
  
  return unpack(saveIt)
end

function Animal:update(dt)
  self.changed = false
  
  if self.attackCountdown > 0 then
    self.attackCountdown = self.attackCountdown - dt
    
    if self.attackCountdown <= 0 then
      self.attackCountdown = 0
      
      if self.currentJob == "attack" then
        local a = self.trackingObject
        self:setFullAction(a, REGIONS[a.reg], REGIONS[self.reg])
      end
    end
  end
  
  if self.dest ~= nil then
    self:move()
  end
  return self.changed
end

function Animal:die()
  self.health = 0
  
  if self.trackingObject ~= nil then 
    self.trackingObject:removeTracker(self) 
  end
  
  self:informTrackersOfDeath()
  
  REGIONS[self.reg]:addToRemovalQueue(self)
end

-- -- -- -- -- -- -- -- -- --[[
-- MOVING
--  + updating region
--  + performing arrival action
-- -- -- -- -- -- -- -- -- --]]
function Animal:move()
  --print("Moving animal with id " .. self.id .. " and owner  " .. self.owner)
  -- create movement vector
  local moveX = self.dest[1] - self.x
  local moveY = self.dest[2] - self.y
  if moveX > 0 then self.dir = -1 else self.dir = 1 end
  
  -- normalize it
  local magnitude = math.sqrt(moveX*moveX + moveY*moveY)
  
  -- move towards destination
  self.x = self.x + moveX / magnitude * self.speed
  self.y = self.y + moveY / magnitude * self.speed
  
  -- re-check sorted Y position
  REGIONS[self.reg]:checkPosition(self)
  
  -- if we've reached the destination, stop there!
  if magnitude < self.speed then
    self.x = self.dest[1]
    self.y = self.dest[2]
    
    self:checkRegion()
    self:removeDestination()
    self.jumpAnim = 0
    
    self:informTrackers()
    
  -- if we're not there yet, simulate a jumpy run movement
  else 
    if self.speed < 0.1 * self.terrainModifier then
      -- start a new jump
      self.speed = self.maxSpeed * self.terrainModifier
      
      -- decrease speed if we are carrying something
      if self.item ~= nil then
        self.speed = self.speed * (0.6 + (self.DNA[2][1] + self.DNA[2][2])*0.2)
      end
      
      self.jumpAnim = 0
      self:checkRegion()
      
      -- inform those who track US
      self:informTrackers()
      
      -- and follow the animal WE are tracking
      if self.tracking and self.updateTracking then
        local aO = self.trackingObject
        if aO ~= nil then
          self:setFullAction(aO, REGIONS[aO.reg], REGIONS[self.reg])
          self.updateTracking = false
        else
          -- if the animal doesn't exist anymore, we can of course stop tracking
          self.tracking = false
          self.updateTracking = false
        end
      end
    else 
      -- continue moving
      self.speed = self.speed * 0.9
      
      -- play jumping animation
      if self.speed > self.maxSpeed * self.terrainModifier * 0.4 then
        self.jumpAnim = math.clamp(0, self.jumpAnim + 0.25, 1)
      else
        self.jumpAnim = math.clamp(0, self.jumpAnim - 0.08, 1)
      end
    end
  end
  
  -- tell the world we've changed position
  self.changed = true
end

function Animal:switchRegion(r)
  local oldReg = REGIONS[self.reg]
  oldReg:removeAnimal(self)
  oldReg:updatePresence(self.owner, -1)
  
  local prevTerrain = oldReg:getTerrain()
  local newRegion = REGIONS[r]
  
  -- take the weather with you, with some probability
  if oldReg.weatherStatus > 0 and math.prandom(0,1) > 0.75 then
    if newRegion.weatherStatus == 0 then
      newRegion:startWeather()
    end
    newRegion.weatherStatus = oldReg.weatherStatus
    oldReg:stopWeather()
  end
  
  -- send signals to unfriendly animals
  if newRegion.animals > 0 then
    local n = newRegion.nature
    for i=1,#n do
      local a = n[i]
      if a.class > 0 and not self:isFriendly(a:getOwner()) then
        -- found an unfriendly animal, send it a signal
        a:receiveSignal({"flee", self, self.reg})
      end
    end
  end
  
  self.reg = r
  
  -- calculate speed on new terrain
  -- TO DO: I think this can be much simpler, by only taking into account what's currently underneath us, instead of where we came from
  local newTerrain = newRegion:getTerrain()
  if newTerrain >= 7 then
    if newTerrain > prevTerrain  then 
      self.terrainModifier = 0.25
    else  
      self.terrainModifier = 1
    end
  else
    self.terrainModifier = 1
  end
  
  newRegion:addAnimal(self)
  newRegion:updatePresence(self.owner, 1)
end

function Animal:checkRegion()
  -- check if we're still in our own region
  local result = REGIONS[self.reg]:hitTest(self.x, self.y)
  if result then return end
  
  -- check if we've moved to a neighbour region
  local regConn = REGIONS[self.reg]:getConnections()
  for i=1,#regConn do
    result = REGIONS[regConn[i]]:hitTest(self.x, self.y)
    if result then
      self:switchRegion(regConn[i])
      return
    end
  end
  
  -- in the rare case that we jump multiple regions at the same time, keep checking neighbours
  for i=1,#regConn do
    local tempRegConn = REGIONS[regConn[i]]:getConnections()
    for j=1,#tempRegConn do
      result = REGIONS[tempRegConn[j]]:hitTest(self.x, self.y)
      if result then
        self:switchRegion(tempRegConn[j])
        return
      end
    end
  end
   
  print("WENT WRONG; if you see this, there's something seriously wrong")
  
end

function Animal:isInside(i)
  return (self.reg == i and self.inside)
end

function Animal:isNature()
  return false
end

function Animal:resetGoal()
  self.myGoal = nil
end

function Animal:resetJob(newA)
  self.currentJob = ""
  self.jobID = -1
  self.headAnim = 0
  
  -- if our job is reset, and nothing is planned, plan an idle jump
  if newA == nil then
    EVENTS:addEvent({math.randexp(IDLE_JUMP_TIME), "idlejump", self})
    self.arrivalAction = nil
  end
end

function Animal:setArrivalAction(a)
  
  local newA = nil
  local c = a:getClass()
  
  -- stop tracking
  if self.trackingObject ~= nil then
    if self.tracking and (c == "region" or a.id ~= self.trackingObject.id) then
      self.tracking = false
      self.trackingObject:removeTracker(self)
    end
  end
  
  -- make sure we move out of any building we're inside of 
  if self.inside and ((c ~= "region" and not a.inside) or (c == "region" and (a.index ~= self.reg or not HOVER_INSIDE))) then
    self:goViaBuilding()
  end
  
  -- if we click somewhere else while chatting, stop doing so
  if self.currentJob == "chat" then
    self:resetJob()
    self.arrivalActionObject:resetJob()
  end
  
  if c == "region" or c <= 0 then
    -- if somebody's attacking us and we click away, flee!
    if self.currentJob == "attack" then
      self.currentJob = "flee"
    end
  else
    -- we shouldn't be able to do something to ourselves
    if a.id == self.id then
      return
    end
  end
  
  if c == "region" then
    -- regions have no arrival action
  elseif c == 0 then
    
    local reachable = self:alterDestination(a:getRandomPointAround())
    if not reachable then
      return
    end

    -- if it's OUR building or from our FRIENDS
    if self:isFriendly(a:getOwner()) then
      if a:getHealth() < a:getMaxHealth() then
        -- if it's damaged/inactive, build/repair it
        local checkResources, subclassTargets = a:checkResources(self.item)

        if checkResources then
          -- build if we have enough resources
          newA = "build"
        else
          -- look for resources if not
          self:setGoal({"build", a, subclassTargets})
          return
        end
      else
        -- if the home is up and running, get inside
        newA = "home"
      end
    else
      -- if's not our building, start destroying it
      newA = "destroy"
    end
  elseif c == -1 then
    -- if it's a plant, start eating on arrival
    newA = "nutrition"
  elseif c == -2 then
    -- if it's an item, pick it up on arrival
    newA = "itemfetch"
  elseif c < -2 then
    newA = "breaknature"
    local reachable = self:alterDestination(a:getRandomPointAround())
    if not reachable then
      return
    end
  elseif c > 0 then
    -- if it can't be reached, do nothing!
    local reachable = self:alterDestination(a:getRandomPointAround())
    if not reachable then
      return
    end
    
    -- if it's an animal (and it's not the same one we're already interacting with)...
    if self.trackingObject == nil or self.trackingObject.id ~= a.id then
      a:addTracker(self)
      self.tracking = true
      self.trackingObject = a
    end
    
    -- if it's friendly...
    if self:isFriendly(a:getOwner()) then
      -- if we have an item, transfer it
      -- otherwise, simply socialize
      if self.item ~= nil then
        newA = "itemtransfer"
      else
        newA = "chat"
      end
    else
      -- if it's not friendly, ALWAYS ATTACK! NOW! ARGH!
      newA = "attack"
    end
  end
  
  -- if we're about to switch to something else, stop doing our current job
  if newA ~= self.arrivalAction then
    self:resetJob(newA)
  end
  
  self.arrivalAction = newA
  self.arrivalActionObject = a
end

function Animal:setDestination(X, Y, endRegion, path)
  -- if the path is nil, for whatever reason, tell us and don't do anything
  if path == nil then
    self.dest = nil
    print("NO PATH POSSIBLE")
    return
  end
  
  -- add final destination to path, start running to first vertex
  self.totalDest = path 
  table.insert(self.totalDest, {X, Y})
  self.dest = self.totalDest[1]
end

function Animal:goViaBuilding()
  local b = REGIONS[self.reg].building
  table.insert(self.totalDest, 1, {b.x, b.y, 0})
  self.dest = self.totalDest[1]
end

function Animal:removeDestination()
  -- if we still have a way to go, get the next location
  if #self.totalDest > 1 then
    if self.totalDest[1][3] ~= nil then
      self:setInside(false)
    end
    table.remove(self.totalDest, 1)
    self.dest = self.totalDest[1]
    
  -- if not, stop here
  else
    self.dest = nil
    self.jumpAnim = 0
    if self.arrivalAction ~= nil then 
      self:performArrivalAction() 
    end
  end
end

function Animal:alterDestination(X,Y)
  if self.dest == nil then
    return false
  end
  
  if #self.totalDest <= 1 then
    self.dest = {X,Y}
  else 
    self.totalDest[#self.totalDest] = {X,Y}
  end
  return true
end

function Animal:performArrivalAction()
  if self.arrivalActionObject == nil or self.arrivalActionObject.health <= 0 then
    -- if our arrival object has died in the meantime, don't do anything
    self.arrivalActionObject = nil
    return
  else
    -- actually visually face whatever we are facing
    if self.arrivalActionObject:getX() > self.x then
      self.dir = -1
    else
      self.dir = 1
    end
  end
  
  local a = self.arrivalAction
  local r = REGIONS[self.reg]
  
  if self.tracking and a ~= "attack" then
    self.tracking = false
    if self.trackingObject ~= nil then
      self.trackingObject:removeTracker(self)
    end
  end
  
  -- if we arrive at home, get inside, and immediately look for somebody to procreate
  if a == "home" then
    self:resetJob(nil)
    
    self:setInside(true)
    
    local n = r.nature
    for i=1,#n do
      local n2 = n[i]
      if n2:getID() ~= self:getID() and n2.inside and n2:getClass() == self:getClass() and n2:getGender() ~= self:getGender() then
        if n2:isAvailable() and self:isAvailable() then
          self.currentJob = "procreating"
          n2.currentJob = "procreating"
          
          -- place them close together, facing each other
          self.dir = -1
          n2.x = self.x + (self.scale + n2.scale)*75*0.5
          n2.y = self.y
          n2.dir = 1
          
          -- decide who's the male and who's the female
          local female = n2
          local male = self
          if self:getGender() then
            female = self
            male = n2
          end
          
          EVENTS:addEvent({5, "pregnant", female, male})
        end
      end
    end
  elseif a == "build" then
    -- if we were already building here, don't do anything new
    if self.jobID == r.building:getID() then
      return
    end
    
    -- if we have an item, transfer it to the building
    if self.item ~= nil then
      r.building:addResource(self.item.subclass)
      self:useItem()
    end
    
    self.headAnim = 1
    
    -- plan an event to increase the health
    self.jobID = r.building:getID()
    self.currentJob = "build"
    EVENTS:addEvent({self.buildingSpeed, "build", r.building, 1, self})
  elseif a == "destroy" then
    -- if we were already destroying here, don't do anything new
    if self.jobID == r.building:getID() then
      return
    end
    
    self.headAnim = 1
    
    -- plan an event to increase the health
    self.jobID = r.building:getID()
    self.currentJob = "destroy"
    EVENTS:addEvent({5, "destroy", r.building, -1, self})
  elseif a == "nutrition" then
    
    -- self.jobID = jobID should be set to the current plant 
    self.currentJob = "nutrition"
    self.jobID = self.arrivalActionObject:getID()
    EVENTS:addEvent({EATING_SPEED, "nutrition", self, 1, self.arrivalActionObject})
  elseif a == "itemfetch" then
    self:grabItem(self.arrivalActionObject)
    self.arrivalAction = ""
      
    self:finishedAction(a)
  elseif a == "itemtransfer" then
    self:transferItem(self.arrivalActionObject)
    self.arrivalAction = ""
      
    self:finishedAction(a)
  elseif a == "breaknature" then
    -- if we were already breaking stuff down here, don't do anything new
    if self.jobID == self.arrivalActionObject:getID() then
      return
    end
    
    self.headAnim = 1
    
    -- plan an event to increase the health
    self.jobID = self.arrivalActionObject:getID()
    self.currentJob = "breaknature"
    EVENTS:addEvent({5, "breaknature", self.arrivalActionObject, -1, self})
  elseif a == "attack" then
    self.currentJob = "attack"
    self.trackingObject:takeHit(self)
    
    if self.trackingObject == nil or self.trackingObject.health <= 0 then
      -- if we've killed our target, stop fighting
      self.trackingObject = nil
      self:resetJob(nil)
      self:finishedAction(a)
    else
      -- if not, plan the next attack
      self.attackCountdown = 2
      self.headAnim = 1
      
      if self.trackingObject.illness > 0 then self:updateCondition(0) end
      if self.illness > 0 then self.trackingObject:updateCondition(0) end
    end
    
  elseif a == "flee" then
    self:resetJob()
    self:finishedAction(a)
    
  elseif a == "chat" then
    self.currentJob = "chat"
    self.arrivalActionObject.currentJob = "chat"
    EVENTS:addEvent({10, "chat", self, self.arrivalActionObject})
  end
end

function Animal:setInside(newValue)
  self.inside = newValue
  if self.item ~= nil then
    self.item.inside = newValue
  end
end

-- -- -- -- -- -- -- -- -- --[[
-- FIGHTING
-- -- -- -- -- -- -- -- -- --]]
function Animal:takeHit(attacker)
  local damage = attacker.attackStrength - self.defenseStrength
  
  -- if damage is actually dealt, execute it
  if damage > 0 then
    self:updateHealth(-damage)
  end
  
  -- TO DO: something to decide whether to keep fleeing, or attack back!
  
  -- if we're not already attacking, and we're not fleeing, start doing so!
  local shouldFlee = false
  if self.currentJob ~= "attack" and not shouldFlee then
    self:setFullAction(attacker, REGIONS[attacker.reg], REGIONS[self.reg])
  end
end

function Animal:updateHealth(dh)
  self.health = self.health + dh
  
  if self.health <= 0 then
    self:die()
  elseif self.health >= self.maxHealth then
    self.health = self.maxHealth
  end
end

function Animal:getRandomPointAround()
  local randSign = math.rsign()
  local X,Y = self:getX() + randSign * math.prandom(40, 60) * self.scale, self:getY() + math.prandom(-5,5)
  
    -- if this leads to a destination outside of target region, change it
  while not REGIONS[self.reg]:generalHitTest(X, Y, REGIONS[self.reg].polygon) do
    randSign = math.rsign()
    X,Y = self:getX() + randSign * math.prandom(40, 60) * self.scale, self:getY() + math.prandom(-5,5)
  end
  
  return X,Y
end

-- TO DO: add preference: region with home => region with defense tower => region owned by us => region unowned => anything
function Animal:findSuitableNeighbour(enemyRegion)
  local secondBest = nil
  local myReg = REGIONS[self.reg]
  
  -- go through all neighbours
  for i=1,#myReg.conn do
    local nei = REGIONS[myReg.conn[i]]
    -- if the enemy didn't come from this region, and it's not impossible for me to be there
    if myReg.conn[i] ~= enemyRegion and not nei:getImpassable() then
      if nei.owner == 0 or nei.owner == self.owner then
        -- if we own the region or it is unowned; go there now!
        return nei
      elseif secondBest == nil then
        -- otherwise, it's a backup in case we don't find better regions
        secondBest = nei
      end
    end
  end
  
  return secondBest
end

function Animal:receiveSignal(signal)
  if signal[1] == "flee" then
      
    local destReg = self:findSuitableNeighbour(signal[3])
    
    if destReg ~= nil then
      local p = destReg:completelyRandomPoint()
      self:setDestination(p.x, p.y, destReg, REGIONS[self.reg]:pathFind(destReg, p.x, p.y, self.x, self.y))
      
      self.arrivalAction = "flee"
      self.arrivalActionObject = destReg
      self.currentJob = "flee"
    end

  end
end


-- -- -- -- -- -- -- -- -- --[[
-- ITEMS
-- -- -- -- -- -- -- -- -- --]]
function Animal:grabItem(item)  
  -- only pick up items if we don't already have one, AND if we're strong enough
  if self.item == nil and not item.taken and item.itemWeight <= self.maxItemWeight then
    -- set item to carrying position
    item.x = self.itemPosition[1]
    item.y = self.itemPosition[2]
    
    -- transfer item from region to animal
    self.item = item
    REGIONS[self.reg]:removeNatureByID(item.id)
    self.item:setTaken(true)
    
    -- update the buttons in the GUI
    GUI:updateButtons()
  end
end

function Animal:dropItem()
  self.item.x = self.x - self.item.x * self.scale * self.dir
  self.item.y = self.y
  
  self.item:setTaken(false)
  
  REGIONS[self.reg]:sortedInsert(self.item)
  self.item = nil
end

function Animal:useItem()
  self.item = nil
  GUI:updateButtons()
end

function Animal:setItem(item)
  item.x = self.itemPosition[1]
  item.y = self.itemPosition[2]
  
  self.item = item
end

function Animal:getItem()
  if self.item == nil then return nil end
  return self.item:getName()
end

function Animal:transferItem(animal)
  animal:setItem(self.item)
  self.item = nil
end

function Animal:isFriendly(c)
  return (PLAYERS[self.owner].friendList[c] > 0)
end

-- -- -- -- -- -- -- -- -- --[[
-- ANIMAL TRACKING
-- -- -- -- -- -- -- -- -- --]]

function Animal:addTracker(a)
  table.insert(self.trackers, a)
end

function Animal:removeTracker(a)
  for i=1,#self.trackers do
    local tr = self.trackers[i]
    
    if tr.id == a.id then
      tr.tracking = false
      tr.updateTracking = false
      tr.trackingObject = nil
      table.remove(self.trackers, i)
      break
    end
  end
end

function Animal:informTrackersOfDeath()
  for i=1,#self.trackers do
    local tr = self.trackers[i]
    tr.tracking = false
    tr.updateTracking = false
    tr.trackingObject = nil
  end
  
  self.trackers = {}
end

function Animal:informTrackers()
  if #self.trackers < 1 then
    return
  end

  for i=1,#self.trackers do
    local t = self.trackers[i]
    t.updateTracking = true
  end
end

-- -- -- -- -- -- -- -- -- --[[
-- PROPERTIES
-- -- -- -- -- -- -- -- -- --]]

function Animal:establishSpecialty()
  local d = self.DNA
  local scores = {}
  
  scores[1] = d[2][1] + d[2][2] + d[5][1] + d[5][2] -- builder = strength + intelligence
  scores[2] = d[6][1] + d[6][2] + d[8][1] + d[8][2] -- caretaker = caring + social
  scores[3] = d[3][1] + d[3][2] + d[7][1] + d[7][2] -- fighter = fighting + sight
  scores[4] = d[1][1] + d[1][2] + d[4][1] + d[4][2] -- survivor = speed + health
  
  local index,maxScore = 1, scores[1]
  
  for i=2,4 do
    if scores[i] > maxScore then
      index = i
      maxScore = scores[i]
    end
  end
  
  if index == 1 then
    self.specialty = "BUILDER"
  elseif index == 2 then
    self.specialty = "WORKER"
  elseif index == 3 then
    self.specialty = "FIGHTER"
  elseif index == 4 then
    self.specialty = "SURVIVOR"
  end
  
end

function Animal:getSpecialty()
  return self.specialty
end

function Animal:setProperties(a)
  -- if we're past the maximum age, we should die
  if a > ANIMAL_PROPS[self.class][1] then
    self:die()
  end
  
  -- DNA coding:
  -- 1: Speed (can move quickly)
  -- 2: Strength (can carry big things, build quickly)
  -- 3: Sight (for seeing enemies sooner, less fog of war)
  -- 4: Health (doesn't get sick easily, doesn't lose health easily)
  -- 5: Intelligence (for building stuff, and inventing)
  -- 6: Caring (for babies, and nature)
  -- 7: Fighting (training, creating weapons, as well as execution)
  -- 8: Social (for establishing friendships and allies)
  -- 9: Fur Colour
  -- 10: Eye Colour
  
  -- set age, scale, speed, blabla
  self.age = a
  self.scale = self.age / ANIMAL_PROPS[self.class][1] * ANIMAL_PROPS[self.class][2]
  self.maxSpeed = ANIMAL_PROPS[self.class][6] * self.age / ANIMAL_PROPS[self.class][1] * (1 + (self.DNA[1][1] + self.DNA[1][2]) * 0.2) * (1 / (self.illness + 1))
  self.jumpSpeed = self.maxSpeed * 2
  
  self.attackStrength = self.age / ANIMAL_PROPS[self.class][1] * ANIMAL_PROPS[self.class][9] * (0.5 + (self.DNA[2][1] + self.DNA[2][2])*0.1 + (self.DNA[7][1] + self.DNA[8][1])*0.2) *  (1 / (self.illness + 1))
  
  self.defenseStrength = self.age / ANIMAL_PROPS[self.class][1] * ANIMAL_PROPS[self.class][10] * (1 + (self.DNA[4][1] + self.DNA[4][2])*0.2 + (self.DNA[2][1] + self.DNA[2][2] + self.DNA[7][1] + self.DNA[7][2]) * 0.1) *  (1 / (self.illness + 1))
  
  self.maxItemWeight = self.age / ANIMAL_PROPS[self.class][1] * ANIMAL_PROPS[self.class][7] * 0.06 * (1 + (self.DNA[2][1] + self.DNA[2][2]) * 0.5) *  (1 / (self.illness + 1)) * 100 -- TO DO: remove 100 in final game
  
  self.buildingSpeed = (1 - (self.DNA[5][1] + self.DNA[5][2] + self.DNA[2][1] + self.DNA[2][2])*0.1) * ANIMAL_PROPS[self.class][8] 
  
  self.illnessResistance = 0.75 + (self.DNA[4][1] + self.DNA[4][2])*0.1
  self.recoverySpeed = (self.DNA[4][1] + self.DNA[4][2])*0.5 + 0.5 - self.illness * 0.5
  
  self.maxHealth = 10
end

-- -- -- -- -- -- -- -- -- --[[
-- DRAWING (animal + shadow)
-- -- -- -- -- -- -- -- -- --]]
function Animal:draw(h, s, sl, tsl)
  love.graphics.push()
  
  -- scales and translates the canvas to where the animal should be
  love.graphics.scale(self.scale * self.dir, self.scale)
  love.graphics.translate(self.graphicTranslationX, self.graphicTranslationY)
  
  -- DEBUGGING PURPOSES
  love.graphics.setColor(0,0,0)
  love.graphics.print(self.reg, 50, 100)
  if self.trackingObject ~= nil then
    love.graphics.print(tostring(self.trackingObject), 50, 120)
  end
  love.graphics.print(tostring(self.tracking), 50, 140)
  love.graphics.print(tostring(#self.trackers), 50, 160)
  -- love.graphics.print(tostring(self.updateTracking), 50, 180)

  CAMERA:addToStencil(self)

  -- if we're zoomed out, only draw outline
  if sl then
    love.graphics.setColor(COLOUR_MAP[self.owner]:getAlpha(150))
    love.graphics.circle('fill', 50, 50, 50, 50)
    love.graphics.circle('line', 50, 50, 50, 50)
    
    love.graphics.setColor(ANIMAL_COLOUR_MAP[self.class]:get())
    love.graphics.setLineWidth(10)
    love.graphics.polygon('line', self.outlinePoly)
    
    -- visual feedback for hovering
    if self.hover then
      love.graphics.setLineWidth(30)
      love.graphics.circle('line', 50, 50, 80, 80)
    end
    
  -- otherwise, draw the whole thing
  else    
    
    -- creates every polygon, using the randomly generated colours   
    love.graphics.push()
    
    -- if we're jumping, move our back leg
    if self.jumpAnim ~= 0 then
      local backLegX = self.backLegPivot.x
      love.graphics.translate(backLegX, self.backLegPivot.y)
      love.graphics.rotate(self.jumpAnim * -1)
      love.graphics.translate(-backLegX, -self.backLegPivot.y)
    end
    
    for i=1,#self.backLegPoly do
      love.graphics.setColor(self.colors[4][i]:get())
      love.graphics.polygon('fill', self.backLegPoly[i])
    end
    
    love.graphics.pop()
    
    self.idleAnim = self.idleAnim - self.idleAnimDir*0.1
    
    love.graphics.translate(0, self.idleAnim)
    
    love.graphics.push()
    -- if we're attacking or breaking/building stuff, animate front paw
    if self.frontLegAnim > 0 then
      love.graphics.translate(self.frontLegPivot.x, self.frontLegPivot.y)
      love.graphics.rotate(self.frontLegAnim * 0.45)
      love.graphics.translate(-self.frontLegPivot.x, -self.frontLegPivot.y)
    end
    
    for i=1,#self.frontLegPoly do
      love.graphics.setColor(self.colors[3][i]:get())
      love.graphics.polygon('fill', self.frontLegPoly[i])
    end
    
    love.graphics.pop()
    
    for i=1,#self.bodyPoly do
      love.graphics.setColor(self.colors[2][i]:get())
      love.graphics.polygon('fill', self.bodyPoly[i])
    end
    
    love.graphics.push()
    
    -- if we're attacking or breaking/building stuff, animate front paw
    if self.headAnim > 0 then
      love.graphics.translate(self.headPivot.x, self.headPivot.y)
      love.graphics.rotate(math.clamp(0, (self.headAnim - 0.5) * 0.25, 1))
      love.graphics.translate(-self.headPivot.x, -self.headPivot.y)
      self.headAnim = self.headAnim - 0.05
    
      if self.headAnim <= 0 then
        self.headAnim = 1
      end
    end

    for i=1,#self.headPoly do
      love.graphics.setColor(self.colors[1][i]:get())
      love.graphics.polygon('fill', self.headPoly[i])
    end
    
    love.graphics.pop()
    
    love.graphics.translate(0, -self.idleAnim)
    
    if math.abs(self.idleAnim) > 1 then
      self.idleAnimDir = self.idleAnimDir * -1
    end
    
    local j = self.currentJob
    local aA = self.arrivalAction
    local c = COLOUR_MAP[self.owner]
    love.graphics.setColor(c:get())
    
    -- draws status above animal
    if j == "procreating" or j == "pregnant" then
      -- display heart
      love.graphics.polygon('fill', {49.8, -0.8, 29.3, -17.6, 11.4, -52.9, 30.4, -68, 49.8, -58.6})
      
      love.graphics.setColor(c:getLight())
      love.graphics.polygon('fill', {49.8, -0.8, 70.2, -17.6, 87, -52.9, 68.5, -68.5, 49.8, -58.6})
      
      love.graphics.setColor(c:getDark())
      love.graphics.polygon('line', {68.5, -68.5, 49.8, -58.6, 30.4, -68, 11.4, -52.9, 29.3, -17.6, 49.8, -0.8, 70.2, -17.6, 87, -52.9})
      
    elseif j == "build" or aA == "build" then
      -- display hammer
      love.graphics.polygon('fill', {59.5, -4.5, 60.5, -25.5, 57.5, -48.5, 43.5, -48.5, 41.5, -24.5, 42.5, -4.5})
      
      love.graphics.setColor(c:getLight())
      love.graphics.polygon('fill', {57.5, -48.5, 73.5, -48.5, 74.5, -66.5, 35.5, -66.5, 22.5, -49.5, 43.5, -48.5})
      
      love.graphics.setColor(c:getDark())
      love.graphics.polygon('line', {22.5, -49.5, 35.5, -66.5, 74.5, -66.5, 73.5, -48.5, 57.5, -48.5, 60.5, -25.5, 59.5, -4.5, 42.5, -4.5, 41.5, -24.5, 43.5, -48.5})
    
    elseif j == "nutrition" or aA == "nutrition" then
      -- display knife and fork
      love.graphics.polygon('fill', {72.3, -7.2, 73.8, -12.2, 72.3, -15.7, 24.7, -62.3, 21.5, -64.7, 19.5, -61.8, 20.3, -53.2, 25, -43.8, 34.2, -37, 41.3, -33.7, 63.7, -6.5, 68.7, -5.3})
      
      love.graphics.setColor(c:getLight())
      love.graphics.polygon('fill', {35, -7, 30, -5.3, 25.3, -7, 23.8, -11.7, 24.8, -15.5, 54, -40.8, 60.8, -35 	})
      love.graphics.polygon('fill', {66.5, -41, 80.5, -53.7, 82.5, -53, 82.5, -50.5, 71.3, -35 	})
      love.graphics.polygon('fill', {54, -40.8, 51, -45.7, 52.7, -53, 59.3, -49.2, 60.7, -47.2, 65.2, -43, 66.5, -41, 71.3, -35, 65.5, -33.2, 60.8, -35 	})
      love.graphics.polygon('fill', {52.7, -53, 69.5, -64.7, 73, -63.2, 59.3, -49.2 	})
      love.graphics.polygon('fill', {60.7, -47.2, 75.2, -59.2, 77.3, -59.2, 77.3, -57.2, 65.2, -43 	})
      
      love.graphics.setColor(c:getDark())
      love.graphics.polygon('line', {65.5, -33.2, 71.3, -35, 82.5, -50.5, 82.5, -53, 80.5, -53.7, 66.5, -41, 65.2, -43, 77.3, -57.2, 77.3, -59.2, 75.2, -59.2, 60.7, -47.2, 59.3, -49.2, 73, -63.2, 69.5, -64.7, 52.7, -53, 51, -45.7, 54, -40.8, 50.1, -37.4, 24.7, -62.3, 21.5, -64.7, 19.5, -61.8, 20.3, -53.2, 25, -43.8, 34.2, -37, 41.3, -33.7, 43.2, -31.4, 24.8, -15.5, 23.8, -11.7, 25.3, -7, 30, -5.3, 35, -7, 49.9, -23.2, 63.7, -6.5, 68.7, -5.3, 72.3, -7.2, 73.8, -12.2, 72.3, -15.7, 56.9, -30.8, 60.8, -35})
      
    elseif j == "destroy" or aA == "attack" then
      -- display sword
      love.graphics.polygon('fill', {67.7, -8.8, 59.4, -14.7, 51.8, -21.3, 19.9, -44.9, 21.1, -61.1, 69.6, -10.7})
      love.graphics.polygon('fill', {59.4, -14.7, 49.3, -6.5, 42.3, -9.6, 51.8, -21.3})
      
      love.graphics.setColor(c:getLight())
      love.graphics.polygon('fill', {21.1, -61.1, 37.4, -61.3, 59.1, -28.2, 65.9, -20.9, 71.4, -12.3, 69.6, -10.7})
      love.graphics.polygon('fill', {59.1, -28.2, 72.1, -37.7, 74.7, -29.2, 65.9, -20.9})
      
      love.graphics.setColor(c:getDark())
      love.graphics.polygon('line', {67.7, -8.8, 59.4, -14.7, 49.3, -6.5, 42.3, -9.6, 51.8, -21.3, 19.9, -44.9, 21.1, -61.1, 37.4, -61.3, 59.1, -28.2, 72.1, -37.7, 74.7, -29.2, 65.9, -20.9, 71.4, -12.3})
    
    elseif j == "chat" then
      -- display text bubble
      love.graphics.polygon('fill', {42.5, -16.5, 85.5, -17.5, 94.5, -26.5, 96.5, -45.5, 91.5, -62.5, 71.5, -68.5, 36.5, -66.5, 15.5, -66.5, 5.5, -53.5, 6.5, -26.5, 10.5, -20.5, 20.5, -17.5})
      love.graphics.polygon('fill', {15.5, 1.5, 29.5, -4.5, 42.5, -16.5, 20.5, -17.5, 19.5, -8.5, 13.5, 0.5})
      
      love.graphics.setColor(c:getLight())
      love.graphics.polygon('fill', {19, -57, 51, -60, 74, -59, 82, -60, 80, -56, 67, -56, 47, -56, 18, -55})
      love.graphics.polygon('fill', {18, -49, 36, -50, 51, -49, 61, -50, 60, -47, 45, -46, 32, -46, 18, -46})
      love.graphics.polygon('fill', {19, -39, 36, -40, 64, -39, 70, -40, 71, -37, 62, -36, 43, -37, 22, -36, 19, -37})
      love.graphics.polygon('fill', {20, -30, 38, -29, 51.9, -29, 66.3, -29.5, 67.2, -26.8, 54.2, -25.8, 32.8, -25.8, 20, -26.8})
      
      love.graphics.setColor(c:getDark())
      love.graphics.polygon('line', {15.5, 1.5, 29.5, -4.5, 42.5, -16.5, 85.5, -17.5, 94.5, -26.5, 96.5, -45.5, 91.5, -62.5, 71.5, -68.5, 36.5, -66.5, 15.5, -66.5, 5.5, -53.5, 6.5, -26.5, 10.5, -20.5, 20.5, -17.5, 19.5, -8.5, 13.5, 0.5})
    else
      -- default; display health bar (flip to right direction)
      local startX, endX = 0, 100 * self.health/self.maxHealth
      if self.dir == -1 then
        startX = 100
        endX = -endX
      end
      
      love.graphics.rectangle('fill', startX, -10, endX, 10)
      love.graphics.rectangle('line', startX, -10, endX, 10)
      
      love.graphics.setColor(c:getAlpha(50))
      love.graphics.rectangle('fill', 0, -10, 100, 10)
      
    end
    
    -- visual feedback for attacks (and other stuff?)
    if self.attackCountdown > 0 then
      love.graphics.setColor(255, 0, 0, self.attackCountdown*70)
      for i=1,#self.outlinePolyTriangles do
        love.graphics.polygon('fill', self.outlinePolyTriangles[i])
      end
    end
    
    -- visual feedback for hovering
    if self.hover then
      love.graphics.setColor(COLOUR_MAP[self.owner]:get())
      for i=1,#self.outlinePolyTriangles do
        love.graphics.polygon('fill', self.outlinePolyTriangles[i])
      end
    end
  end
  
  -- restores the canvas to previous position
  love.graphics.pop()
  
  -- display item, if available
  if self.item ~= nil then
    self.item:itemDraw(self.graphicTranslationX * self.scale, (self.graphicTranslationY + self.idleAnim) * self.scale, self.scale, self.dir)
  end
end

-- v is true if the animal is currently visible, and thus shadow also visible
function Animal:shadowDraw(v)
  self.graphicTranslationX = self.x * (1 / self.scale) - self.center[1]
  self.graphicTranslationY = (self.y - self.jumpAnim*self.jumpSpeed) * (1 / self.scale) - self.center[2]
  
  if self.dir == -1 then
    self.graphicTranslationX = -self.x * (1 / self.scale) - 100 + self.center[1]
  end
  
  if not v then return end
  
  love.graphics.push()
  
  love.graphics.scale(self.scale * self.dir, self.scale)
  love.graphics.translate(self.graphicTranslationX, self.graphicTranslationY)
  
  -- creates shadow
  love.graphics.setColor(0, 0, 0, 80)
  love.graphics.ellipse('fill', self.shadow[1], self.shadow[2], self.shadow[3], self.shadow[4])
  
  love.graphics.pop()
end

function Animal:specialDraw()
  love.graphics.push()
  
  love.graphics.scale(self.scale * self.dir, self.scale)
  love.graphics.translate(self.graphicTranslationX, self.graphicTranslationY)
  
  love.graphics.setLineWidth(8)
  love.graphics.setColor(255, 255, 255, 150)
  love.graphics.polygon('line', self.outlinePoly)
  
  if CAMERA:checkScaleLine() then
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setLineWidth(16)
    love.graphics.circle('line', 50, 50, 70, 70)
  end
  
  love.graphics.pop()
  
  -- SHOW CURRENT PATH
  if self.totalDest ~= nil then
    for i=2,#self.totalDest do
      love.graphics.setColor(ROAD_COLOUR:get())
      love.graphics.setLineWidth(3)
      love.graphics.line(self.totalDest[i-1][1], self.totalDest[i-1][2], self.totalDest[i][1], self.totalDest[i][2])
    end
  end
end

-- -- -- -- -- -- -- -- -- --[[
-- HOVERING & SELECTING
-- -- -- -- -- -- -- -- -- --]]

function Animal:unHover()
  self.hover = false
end

function Animal:doHover()
  self.hover = true
end

function Animal:selectAction()
  self.selected = true
  GUI:loadUnit(self)
end

function Animal:deselectAction()
  self.selected = false
  GUI:unload()
end

-- -- -- -- -- -- -- -- -- --[[
-- GETTING & SETTING THINGS
-- -- -- -- -- -- -- -- -- --]]
function Animal:getClass()
  return self.class
end

function Animal:getAge()
  return self.age
end

function Animal:getHealth()
  return self.health
end

function Animal:getOwner()
  return self.owner
end

function Animal:getID()
  return self.id
end

function Animal:getRegion()
  return self.reg
end

function Animal:getX()
  return self.x
end

function Animal:getY()
  return self.y
end

function Animal:getCondition()
  return self.illness
end

function Animal:getActivity()
  if self.currentJob == "" then
    if self.arrivalAction == nil then
      return "IDLE"
    elseif self.arrivalAction == "home" then
      return "GOING HOME"
    elseif self.arrivalAction == "nutrition" then
      return "GETTING FOOD"
    elseif self.arrivalAction == "destroy" then
      return "GOING TO DESTROY"
    elseif self.arrivalAction == "itemfetch" then
      return "FETCHING ITEM"
    elseif self.arrivalAction == "itemtransfer" then
      return "BRINGING ITEM"
    elseif self.arrivalAction == "attack" then
      return "GOING TO ATTACK"
    elseif self.arrivalAction == "build" then
      return "GOING TO BUILD"
    elseif self.arrivalAction == "breaknature" then
      return "GATHERING RESOURCES"
    elseif self.arrivalAction == "chat" then
      return "GOING TO SOCIALIZE"
    end
  elseif self.currentJob == "build" then
    return "BUILDING"
  elseif self.currentJob == "procreating" then
    return "PROCREATING"
  elseif self.currentJob == "pregnant" then
    return "PREGNANT"
  elseif self.currentJob == "nutrition" then
    return "EATING"
  elseif self.currentJob == "destroy" then
    return "DESTROYING"
  elseif self.currentJob == "breaknature" then
    return "GATHERING RESOURCES"
  elseif self.currentJob == "attack" then
    return "ATTACKING"
  elseif self.currentJob == "chat" then
    return "SOCIALIZING"
  elseif self.currentJob == "flee" then
    return "FLEEING"
  end
  
  -- if all else fails, return the current job so I see where it went wrong
  return self.currentJob
end

-- -- -- -- -- -- -- -- -- --[[
-- FOR EVENTS/ACTIONS
-- -- -- -- -- -- -- -- -- --]]
function Animal:getGender()
  return self.gender
end

-- we are available if we're not busy, and we're adults
function Animal:isAvailable()
  return (self.currentJob == "" and self:isAdult())
end

function Animal:isAdult()
  return self.age >= ANIMAL_PROPS[self.class][5]
end

function Animal:setGoal(g) 
  self.myGoal = g
  self:resetJob()
  self:setNextAction(nil)
end

function Animal:finishedAction(t)
  if self.myGoal ~= nil then
    self:setNextAction(t)
  end
end

function Animal:setNextAction(prev)
  -- if the previously finished action means we achieved our goal, stop!
  local g = self.myGoal
  if g[1] == prev then
    self.myGoal = nil
    return
  end
  
  -- this variable will hold whatever object we decide to go to next
  local u, start_r, end_r = nil, nil, nil
  local error_signal = nil
  
  -- decide what to do based on the goal and current state of the world
  if g[1] == "build" then
    if (self.item ~= nil and math.inTable(g[3], self.item.subclass)) then
      -- if we have the item we need, continue building!
      u, end_r, start_r = g[2], REGIONS[g[2]:getRegion()], REGIONS[self.reg]
    else
      -- if we don't have the item, search nature to break or an item to fetch
      u, end_r, start_r = self:searchItem(g[2]:getRegion(), g[3])
      if u == nil then error_signal = "no material" end
    end
  end
  
  -- actually execute it
  if error_signal == nil then
    self:setFullAction(u, end_r, start_r)
  else
    PLAYERS[self.owner]:receiveSignal(error_signal)
  end
end

function Animal:setFullAction(obj, end_region, start_region)
  local newX, newY = obj:getRandomPointAround()
  self:setDestination(newX, newY, end_region, start_region:pathFind(end_region, newX, newY, self.x, self.y))
  self:setArrivalAction(obj)
end

-- -- -- -- -- -- -- -- -- --[[
-- VISIBILITY & HIT-TESTING
-- -- -- -- -- -- -- -- -- --]]
function Animal:checkWithinSelection(bounds)
  if (bounds.x2 < (self.x-self.center[1]*self.scale) or (self.x + (100 - self.center[1])*self.scale) < bounds.x1 or bounds.y2 < (self.y-self.center[2]*self.scale) or (self.y + (100 - self.center[2])*self.scale) < bounds.y1) then
    return false
  end
  
  return true
end

function Animal:checkDistance(x, y)
  if (x < (self.x-self.center[1]*self.scale) or (self.x + (100 - self.center[1])*self.scale) < x or y < (self.y-self.center[2]*self.scale) or (self.y + (100 - self.center[2])*self.scale) < y) then
    return false
  end
  
  return true
end

function Animal:checkCircleDistance(x,y)
  return (x - (self.x - (self.center[1] - 50)*self.scale))^2 + (y - (self.y - (self.center[2] - 50)*self.scale))^2 < (50 * self.scale)^2
end

function Animal:hitTest(X, Y)
  if CAMERA:checkScaleLine() and self:checkCircleDistance(X,Y) then
    return true
  end
  
  if not self:checkDistance(X, Y) then
    return
  end
  
  -- transform input mouse position to match animal
  X = X - self.x + self.center[1]*self.scale
  Y = Y - self.y + self.center[2]*self.scale
  
  if self.dir == -1 then 
    X = 100 * self.scale - X
  end
  
  local c = false
  local p = self.outlinePoly
  local j = #p * 0.5
  for i=1,#p*0.5 do
    if (p[2*i]*self.scale > Y) ~= (p[2*j]*self.scale > Y) then
      if X < (p[2*j-1] - p[2*i-1]) * (Y - p[2*i]*self.scale) / (p[2*j] - p[2*i]) + p[2*i-1]*self.scale then
        c = not c
      end
    end
    j = i
  end

  return c
end

-- -- -- -- -- -- -- -- -- --[[
-- CLEANING
-- -- -- -- -- -- -- -- -- --]]
function Animal:clean()
  self.ears = nil
  self.eyes = nil
  self.shadow = nil

  self.headPoly = nil
  self.bodyPoly = nil
  self.frontLegPoly = nil
  self.backLegPoly = nil
  self.outlinePoly = nil
  
  self.backLegPivot = nil
  
  self.colors = nil
  
  self.jumpAnim = nil
  self.maxSpeed = nil
  self.buildingSpeed = nil
  self.maxItemWeight = nil
  self.attackStrength = nil
  self.defenseStrength = nil
  self.illnessResistance = nil
  self.recoverySpeed = nil
  
  self.graphicTranslationX = nil
  self.graphicTranslationY = nil
  
  if self.arrivalActionObject ~= nil then 
    self.arrivalActionObject = {reg = self.arrivalActionObject:getRegion(), id = self.arrivalActionObject:getID()}
  end
  
  if self.myGoal ~= nil then 
    print_r(self.myGoal)
    for i=1,#self.myGoal do
      local tempFA = self.myGoal[i]
      if type(tempFA) == "table" and tempFA.region ~= nil then
        self.myGoal[i] = {reg = tempFA:getRegion(), id = tempFA:getID()}
      end
    end
  end
  
  for i=1,#self.trackers do
    local t = self.trackers[i]
    self.trackers[i] = {reg = t:getRegion(), id = t:getID()}
  end
  
  if self.trackingObject ~= nil then
    self.trackingObject = {reg = self.trackingObject:getRegion(), id = self.trackingObject:getID()}
  end
end


-- -- -- -- -- -- -- -- -- --[[
-- INITIALIZATION
-- -- -- -- -- -- -- -- -- --]]
function Animal:initialize()
  -- restore link to arrival object
  if self.arrivalActionObject ~= nil then 
    if self.arrivalActionObject.id == nil then
      self.arrivalActionObject = REGIONS[self.arrivalActionObject.reg]
    else
      self.arrivalActionObject = REGIONS[self.arrivalActionObject.reg]:getNatureWithID(self.arrivalActionObject.id) 
    end
  end
  
  if self.trackingObject ~= nil then
    self.trackingObject = REGIONS[self.trackingObject.reg]:getNatureWithID(self.trackingObject.id)
  end
  
  -- restore actual item
  if self.item ~= nil then
    local i = self.item
    self.item = Item(i.id, i.x, i.y, i.scale, i.health, i.region, i.owner, i.location, i.subclass, self.inside)
    self.item:setTaken(true)
  end
  
  -- restore trackers
  for i=1,#self.trackers do
    local t = self.trackers[i]
    self.trackers[i] = REGIONS[t.reg]:getNatureWithID(t.id)
  end
  
  -- restore our goal (object + properties)
  if self.myGoal ~= nil then
    for i=1,#self.myGoal do
      local t = self.myGoal[i]
      if type(t) == "table" and t.reg ~= nil and t.id ~= nil then
        self.myGoal[i] = REGIONS[t.reg]:getNatureWithID(t.id)
      end
    end
  end
  
end

function Animal:initializeDestination(totalDest, dest, arrivalAction, arrivalActionObject, trackingObject)
  self.totalDest = totalDest
  self.dest = dest
  self.arrivalAction = arrivalAction
  self.arrivalActionObject = arrivalActionObject
  self.trackingObject = trackingObject
end

function Animal:initializeJob(currentJob, jobID, trackers, tracking, myGoal, attackCountdown)
  self.currentJob = currentJob
  self.jobID = jobID
  self.trackers = trackers
  self.tracking = tracking
  self.myGoal = myGoal
  self.attackCountdown = attackCountdown
end

function Animal:initializeItem(item)
  self.item = item
end