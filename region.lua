
Region = Object:extend()

function Region:new(index, polygon, centroid)
  self.index = index
  self.polygon = polygon
  self.innerPolygon = {}
  self.centroid = centroid
  self.owner = 0
  self.terrain = 0
  self.conn = {}
  self.removalQueue = {}
  
  self.health = 1
  
  -- actual properties
  self.fertility = math.random(0, 10)
  
  -- for GUI
  self.hover = false
  self.visible = true
  self.selected = false
  self.ownerColor = nil
  
  -- for animals, nature and buildings
  self.nature = {}
  self.trees = 0
  self.animals = 0
  self.building = nil
  self.connLines = {}
  
  self.shoreLines = {}
  self.mountainLines = {}
  self.groundLines = {}
  self.riverLines = {}
  self.amountRivers = 0
  
  self.freeLocations = {}
  self.forbiddenLocations = {}
  
  self.viewInside = false
  
  -- for efficiency
  self.box = {}
  self.playerPresence = {}
  
  -- for fog
  self.fog = 3
  self.fogOwners = {}
  self.fogValues = {}
  self.fogFlag = false
  
  -- for pathfinding
  self.pathDist = 0
  self.pathPrev = nil
  
  -- for weather
  self.weatherStatus = 0
  self.weatherParticles = {}
  self.particleRevive = {}
end

function Region:update(dt)
  -- only update animals; I don't think nature needs updates per se
  for i,n in pairs(self.nature) do
    if n.class > 0 then
      n:update(dt)
    end
  end
  
  -- if stuff is set to be removed, do so
  if #self.removalQueue > 0 then
    for i=1,#self.removalQueue do
      local a = self.removalQueue[i]
      if a.class > 0 then
        self:killAnimal(a)
      elseif a.class == 0 then
        self:removeBuilding()
      elseif a.class == -7 then
        self:removeParticle(a)
      else
        self:removeNature(a)
      end
    end
    
    self.removalQueue = {}
  end
end

function Region:removeParticle(a)
  self:removeNatureByID(a.id)
end

function Region:addToRemovalQueue(what)
  table.insert(self.removalQueue, what)
end

-- -- -- -- -- --[[
-- FOG
-- -- -- -- -- --]]
function Region:setFog(f, fO, fV)
  self.fog = f
  self.fogOwners = fO
  self.fogValues = fV
end

function Region:getFog()
  return self.fog
end

function Region:resetFog(f)
  if f >= 3 then return end
  self.fogFlag = false
  for i,c in pairs(self.conn) do
    if REGIONS[c].fogFlag then REGIONS[c]:resetFog(f + 1) end
  end
end

-- Recursive function for updating the fog
-- It automatically checks all connections, and updates fog there (if necessary)
function Region:updateFog(f, o)
  -- reset all fog flags
  if f == 0 then self:resetFog(0) end
  
  -- if we shouldn't update this one, or it has already been updaed, stop
  if f >= 3 or self.fogFlag then return end
  
  -- set the fog flag to true
  self.fogFlag = true
  
  -- insert the owner into the list of fog influencers
  table.insert(self.fogOwners, o)
  table.insert(self.fogValues, f)
  
  -- otherwise, update the fog and do the same for all neighbours
  self.fog = math.min(f, self.fog)
  for i=1,#self.conn do
    REGIONS[self.conn[i]]:updateFog(f + 1, o)
  end
end

-- Recursive function for removing the fog
-- It checks all connections, and resets them to a previous fog state
function Region:removeFog(f, o)
  -- reset all fog flags
  if f == 3 then self:resetFog(0) end
  
  -- if we shouldn't update this one, or it has alread been updated, stop
  if f <= 0 or self.fogFlag then return end
  
  -- set the fog flag to true
  self.fogFlag = true
  
  -- remove this owner from our fog influencers
  for i,v in pairs(self.fogOwners) do
    if v == o then
      table.remove(self.fogOwners, i)
      table.remove(self.fogValues, i)
      break
    end
  end
  
  -- set new fog to best value in our list
  if #self.fogValues > 0 then
    self.fog = math.getMin(self.fogValues).value
  else
    self.fog = 3
  end
  
  -- do the same for all connections
  for i=1,#self.conn do
    REGIONS[self.conn[i]]:removeFog(f - 1, o)
  end
end

-- -- -- -- -- --[[
-- TERRAIN
-- -- -- -- -- --]]
function Region:adjustTerrain()
  -- we don't want water wells or mountain tops to be removed
  if self.terrain == 1 or self.terrain == 9 then
    return
  end
  
  local count = {0, 0, 0, 0, 0, 0, 0, 0, 0}
  local first = 10
  local last = 0
  
  -- check the neighbours, count occurences and what's highest priority
  for i,c in pairs(self.conn) do
    local t = REGIONS[c]:getTerrain()
    if t > 0 then
      if t < first then
        first = t
      elseif t > last then
        last = t
      end
      count[t] = count[t] + 1
    end
  end
  
  local new_terrain = math.getMax(count).key
  
  local rand = math.prandom(0,1)
  -- formula for "going up probability" is a simple straight line downward
  if rand < -0.1225 * first + 1.1125 then
    new_terrain = first + 1
  end
  
  -- formula for "going down probability" is a simple straight line upward
  if rand < 0.1225 * last - 0.1125 then
    new_terrain = last - 1
  end
  
  -- this ensures we keep more land, instead of letting it go to waste as water or mountain
  if rand < 0.075 and new_terrain >= 3 and new_terrain <= 7 then
    new_terrain = math.clamp(4, new_terrain, 7)
  end
  
  -- if water is surrounded by only non-water, we're likely to change it
  if rand < 0.39 and new_terrain == 3 and math.getMax(count).key > 3 then
    new_terrain = 4
  end

  -- make sure we don't create terrain types that don't exist
  new_terrain = math.clamp(1, new_terrain, 9)
  
  -- actually set the region to the new terrain
  self:setTerrain(new_terrain)
end

function Region:setTerrain(terrain)
  self.terrain = terrain
  self.color = TERRAIN_COLOUR_MAP[self.terrain]
end

function Region:getTerrain()
  return self.terrain
end

function Region:cleanRiver()
  
  for _,c in pairs(self.conn) do
    local t = REGIONS[c]
    if t.terrain <= 3 then
      self.riverLines[c] = nil
    end
  end
    
end

function Region:adjustRiver()
  
  if self.terrain <= 3 then return end
  
  for _,c in pairs(self.conn) do
    local t = REGIONS[c]

    -- if our neighbour is water, and we're not
    if t:getTerrain() <= 3 then
      if t.amountRivers < 2 then
        -- start a river
        self.riverLines[c] = 3
        self.amountRivers = self.amountRivers + 1
        t.amountRivers = t.amountRivers + 1
      end
    end
    
    if self.riverLines[c] ~= nil then
      -- if the edge between us and this neighbour is a river
      
      -- decide whether to continue on our own region, or the neighbour's
      local reg1, reg2, line = nil, nil, nil
      
      if self.amountRivers <= (#self.conn - 3) then
        reg1, reg2 = self, t
        line = self.connLines[c]
      end
            
      if t:getTerrain() > 3 and t.amountRivers <= (#t.conn - 3) and math.prandom(0,1) >= 0.25 then
        reg1, reg2 = t, self
        line = t.connLines[self.index]
      end
      
      -- only add a river if it's actually possible/allowed
      if reg1 ~= nil then 
      
        local line1, line2 = nil, nil
        
        -- get the edge before and after this one
        -- get the edge before and after this one
        for _,c2 in pairs(reg1.conn) do
          
          if c2 ~= reg2.index then
            local l = reg1.connLines[c2]
          
            if (l[1] == line[1] and l[2] == line[2]) or (l[1] == line[3] and l[2] == line[4]) then
              -- the first vertex matches
              line1 = c2
            elseif (l[3] == line[1] and l[4] == line[2]) or (l[3] == line[3] and l[4] == line[4]) then
              -- the second vertex matches
              line2 = c2
            end
            
          end
          
        end
        -- extend a river (with an unused edge) with a certain probability
        -- TURNED OFF: and stop searching for this region, for this iteration
        
        if math.prandom(0,1) >= 0.5 then
          local myValue = math.clamp(0.5, self.riverLines[c] - 0.5, 100)
          if line1 ~= nil and reg1.riverLines[line1] == nil and REGIONS[line1].amountRivers <= (#REGIONS[line1].conn - 3) then
            reg1.riverLines[line1] = myValue
            REGIONS[line1].riverLines[reg1] = myValue
            
            reg1.amountRivers = reg1.amountRivers + 1
            reg2.amountRivers = reg2.amountRivers + 1
            -- break
          elseif line2 ~= nil and reg1.riverLines[line2] == nil and REGIONS[line2].amountRivers <= (#REGIONS[line2].conn - 3) then
            reg1.riverLines[line2] = myValue
            REGIONS[line2].riverLines[reg2] = myValue
            
            reg1.amountRivers = reg1.amountRivers + 1
            reg2.amountRivers = reg2.amountRivers + 1
            -- break
          end
        end
      end
      
    end
  end
  
end
  

-- -- -- -- -- -- -- -- -- --[[
-- GETTING & SETTING THINGS
-- -- -- -- -- -- -- -- -- --]]
function Region:getX()
  return self.centroid.x
end

function Region:getY()
  return self.centroid.y
end

function Region:getCentroid()
  return self.centroid
end

function Region:setOwner(owner)
  self.owner = owner
  if owner > 0 then
    self.ownerColor = COLOUR_MAP[self.owner]
  else
    self.ownerColor = nil
  end
end

function Region:getIndex()
  return self.index
end

function Region:getOwner()
  return self.owner
end

function Region:getRegion()
  return self.index
end

function Region:getID()
  return nil
end

function Region:getFertility()
  return self.fertility
end

function Region:getTrees()
  return self.trees
end

function Region:setTrees(t)
  self.trees = t
end

function Region:getAnimals()
  return self.animals
end

function Region:setAnimals(a)
  self.animals = a
end

function Region:getBuilding()
  return self.building
end

function Region:addBuilding(what, owner)
  self:addNature(what, owner)
end

function Region:removeBuilding()
  if self.building == nil then return end
  
  EVENTS:removeObjectFromEvents(self.building)
  self:removeNatureByID(self.building.id)
  
  self.building = nil
end

function Region:removeNature(a)
  local loc = a.location
  table.insert(self.freeLocations, a.location)
  
  local height = math.round( (self.box.y2 - self.box.y1) / REGION_SQUARE )
  
  -- if it's a tree, give back locations (if they are allowed)
  if a.class == -3 then
    self.trees = self.trees - 1
    
    local loco = {loc - 1, loc - 2, loc - 2 - height, loc - 2 + height}
    
    for i=1,#loco do
      if not math.inTable(self.forbiddenLocations, loco[i]) then
        table.insert(self.freeLocations, loco[i])
      end
    end
  end
  
  EVENTS:removeObjectFromEvents(a)
  self:removeNatureByID(a.id)

end

function Region:killAnimal(a)
  EVENTS:removeObjectFromEvents(a)
  self:removeNatureByID(a.id)
  self:addCorpse(a)
end

function Region:addCorpse(a)
  -- id, owner, class, x, y, scale, dir, region, inside, meat, maxMeat
  local meat = a.age * a.nutrition
  local c = Corpse(a.id, a.owner, a.class, a.x, a.y, a.scale, a.dir, a.reg, a.inside, meat, meat, a.DNA)
  self:sortedInsert(c)
end

function Region:removeNatureByID(id)
  for i,n in pairs(self.nature) do
    if n.id == id then
      table.remove(self.nature, i)
      break
    end
  end
end

function Region:getVisibility()
  return self.visible
end

function Region:setPresence(arr)
  self.playerPresence = arr
end

function Region:updatePresence(index, amount)
  self.playerPresence[index] = self.playerPresence[index] + amount
end

function Region:getPresence()
  return self.playerPresence
end

function Region:setBoundingBox(b)
  self.box = b
end

function Region:setInnerPolygon(p)
  self.innerPolygon = p
end

function Region:addShoreLine(x1, y1, x2, y2, cX, cY)
  -- 5th and 6th coordinate: normal for movement vector
  local norm = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
  local x3 = (y2 - y1) / norm
  local y3 = -(x2 - x1) / norm
  
  -- flip the normal to point inside
  if x3 * (cX - x1) + y3 * (cY - y1) <= 0 then
    x3 = x3 * -1
    y3 = y3 * -1
  end
  
  -- 7th coordinate: current position, 8th coordinate: movement boundary/limit
  table.insert(self.shoreLines, {x1, y1, x2, y2, x3, y3, math.random(0,10), 10})
end

function Region:setShoreLines(s)
  self.shoreLines = s
end

function Region:addMountainLine(x1, y1, x2, y2, cX, cY)
  if math.abs(x2 - x1) < 8 then return end
  
  local norm = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
  local x3 = (y2 - y1) / norm
  local y3 = -(x2 - x1) / norm
  
  -- flip the normal to point inside
  if x3 * (cX - x1) + y3 * (cY - y1) <= 0 then
    x3 = x3 * -1
    y3 = y3 * -1
  end
  
  table.insert(self.mountainLines, {x1, y1, x2, y2, x3, y3})
end

function Region:setMountainLines(s)
  self.mountainLines = s
end

function Region:addGroundLine(p)
  table.insert(self.groundLines, p)
end

function Region:setGroundLines(p)
  self.groundLines = p
end

function Region:setRiverLines(r)
  self.riverLines = r
end

function Region:setConnLines(c)
  self.connLines = c
end

function Region:getClass()
  return "region"
end

function Region:setLocations(l, f)
  self.freeLocations = l
  self.forbiddenLocations = f
end

function Region:isInside()
  return false
end

function Region:setWeatherStatus(s)
  self.weatherStatus = s
end

function Region:clean()
  self.pathPrev = nil
  self.weatherParticles = nil
  self.hover = nil
  self.visible = nil
  self.selected = nil
  self.ownerColor = nil
  
  local nat = self.nature
  -- remove particles (set to nil, compact and compress table afterwards)
  for i,n in pairs(nat) do
    if n:getClass() == -7 then
      nat[i] = nil
    end
  end
  
  local j=0
  for i=1,#nat do
    if nat[i] ~= nil then
      j=j+1
      nat[j] = nat[i]
    end
  end
  
  for i=j+1,#nat do
    nat[i]=nil
  end
end

-- -- -- -- -- -- -- -- -- --[[
-- SELECTING & HOVERING
-- -- -- -- -- -- -- -- -- --]]
function Region:selectAction()
  if self.fog == 3 then return end
  self.selected = true
  GUI:loadRegion(self)
end

function Region:deselectAction()
  self.selected = false
  GUI:unload()
end

function Region:unHover()
  self.hover = false
end

function Region:doHover()
  self.hover = true
end

-- -- -- -- -- -- -- -- -- --[[
-- DRAWING
-- -- -- -- -- -- -- -- -- --]]
function Region:draw()
  -- if we're not visible, why bother drawing?
  if not self.visible then
    return 
  end
  
  self.fog = 0
  
  if self.fog < 3 then
    -- draw a different fill, based on the region's state
    if self.hover then
      love.graphics.setColor(self.color:getLight())
    elseif self.selected then
      love.graphics.setColor(250, 220, 180)
    else
      if self.weatherStatus == 2 then
        love.graphics.setColor(230, 230, 230)
      else
        love.graphics.setColor(self.color:get())
      end
    end
    love.graphics.polygon('fill', self.polygon)

    -- draw the outline of the region
    love.graphics.setColor(self.color:getDark())
    love.graphics.setLineWidth(1)
    -- love.graphics.polygon('line', self.polygon)
    
    if self.weatherStatus ~= 2 then
    
      if not self.hover and not self.selected then
        -- draw mountain lines for mountain tiles around it
        if #self.mountainLines > 0 then
          for i=1,#self.mountainLines do
            local s = self.mountainLines[i]
            love.graphics.setColor(TERRAIN_COLOUR_MAP[9]:getDesaturatedDark())
            
            if s[6] < 0 then
              love.graphics.polygon('line', s[1], s[2], s[3], s[4], s[3], s[4]+3, s[1], s[2]+3)
              love.graphics.polygon('fill', s[1], s[2], s[3], s[4], s[3], s[4]+3, s[1], s[2]+3)
            else 
              -- love.graphics.polygon('fill', s[1], s[2], s[3], s[4], s[3], s[4]-2, s[1], s[2]-2)
            end
          end
        end
        
        -- draw watery waves
        if #self.shoreLines > 0 then
          
          -- also draw depth polygons
          for i=1,#self.shoreLines do
            local s = self.shoreLines[i]
            love.graphics.setColor(self.color:getDark())
            if s[6] > 0 then
              --love.graphics.polygon('fill', s[1], s[2], s[3], s[4], s[3] + s[5]*4, s[4] + s[6]*4, s[1] + s[5]*4, s[2] + s[6]*4)
              love.graphics.polygon('line', s[1], s[2], s[3], s[4], s[3], s[4]+11, s[1], s[2]+11)
              love.graphics.polygon('fill', s[1], s[2], s[3], s[4], s[3], s[4]+11, s[1], s[2]+11)
            else 
              love.graphics.polygon('fill', s[1], s[2], s[3], s[4], s[3] + s[5]*3, s[4] + s[6]*3, s[1] + s[5]*3, s[2] + s[6]*3)
            end
          end
          
          love.graphics.setColor(255, 255, 255)
          --love.graphics.print(#self.shoreLines, self.centroid.x, self.centroid.y)
          love.graphics.setLineWidth(2)
          for i=1,#self.shoreLines do
            local s = self.shoreLines[i]
            love.graphics.setColor(100, 200, 255, 120-s[7]*12)
            love.graphics.line(s[1] + s[5]*s[7], s[2] + s[6]*s[7], s[3] + s[5]*s[7], s[4] + s[6]*s[7])
            s[7] = s[7] + 0.04
            if s[7] > s[8] then
              s[8] = 10 + math.prandom(0,4)
              s[7] = 0.6
            end
          end
        end
      end
    end
  end
   
  -- draw fog
  love.graphics.setColor(0, 0, 0, self.fog * 85)
  love.graphics.setLineWidth(1)
  love.graphics.polygon('fill', self.polygon)
  love.graphics.polygon('line', self.polygon)
     
    --[[ FOR DEBUGGING PURPOSES
  local width = math.round( (self.box.x2 - self.box.x1) / REGION_SQUARE )
  local rectW = (self.box.x2 - self.box.x1) / width
  local height = math.round( (self.box.y2 - self.box.y1) / REGION_SQUARE )
  local rectH = (self.box.y2 - self.box.y1) / height
  
   love.graphics.setColor(0,0,0)
  love.graphics.print(#self.freeLocations, self.centroid.x, self.centroid.y)

  for i=1,#self.freeLocations do
    local idX = math.floor(self.freeLocations[i] / height)
    local idY = self.freeLocations[i] % height
    love.graphics.rectangle('line', self.box.x1 + idX*rectW, self.box.y1 + idY*rectH, rectW, rectH)
    love.graphics.print(self.freeLocations[i], self.box.x1 + idX*rectW, self.box.y1 + idY*rectH)
  end
      
    
  love.graphics.setColor(0,0,0)
  love.graphics.ellipse('fill', self.centroid.x, self.centroid.y, 10, 10)
    
  if #self.nature >= 2 then
    love.graphics.setColor(0,0,0,255)
    love.graphics.print("#: " .. self.nature[1].class .. " | " .. self.nature[2].class, self.centroid.x, self.centroid.y)
  end
  
    local tr = love.math.triangulate(self.polygon)
  
  for i=1,#tr do
    love.graphics.setColor(math.prandom(0,255), math.prandom(0,255), math.prandom(0,255))
    love.graphics.polygon("fill", tr[i])
  end

  love.graphics.setColor(0,0,0,255)
  love.graphics.print("S: " .. #self.fogOwners, self.centroid.x, self.centroid.y)
    --]]
end

function Region:drawShadow()
  if not self.visible then
    return
  end
      
  -- draw rivers
  if self.terrain > 3 then
    -- set different color based on terrain
    if self.terrain >= 7 then
      love.graphics.setColor(0,50,120)
    else
      love.graphics.setColor(0, 90, 170)
    end
    
    for _,c in pairs(self.conn) do
      if self.riverLines[c] ~= nil then
        love.graphics.setLineWidth(self.riverLines[c])
        love.graphics.line(unpack(self.connLines[c]))
      end
    end
  end
  
  -- if the region has a building, and it is selected or a bunny inside the building is selected, we're viewing the inside
  if (self.building ~= nil and self.building.health == self.building.maxHealth) and (self.selected or (CUR_UNIT[1] ~= nil and CUR_UNIT[1]:isInside(self.index))) then 
    self.viewInside = true 
  else
    self.viewInside = false
  end
  
  if self.fog < 3 then
    local sl = CAMERA:checkScaleLine()
    local tsl = CAMERA:checkTopScaleLine()
    for i,n in pairs(self.nature) do
      if not (self.fog > 0 and n.class < 0) and n.inside == self.viewInside then
        n:shadowDraw(true, sl, tsl)
      end
    end
  end
end

function Region:drawNature()
  if not self.visible then
    return 
  end
  
  if self.fog < 3 then
    local sl = CAMERA:checkScaleLine()
    local tsl = CAMERA:checkTopScaleLine()
    
    -- show inside, if applicable
    if self.viewInside then
      love.graphics.setColor(75, 35, 0)
      love.graphics.polygon('fill', self.innerPolygon)
      
      love.graphics.setColor(35, 17, 0)
      local p = self.groundLines
      for i=1,#p do
        love.graphics.polygon('fill', p[i])
      end
    end
    
    -- colour overlay to display owner
    if self.ownerColor ~= nil then
      if sl then
        love.graphics.setColor(self.ownerColor:getAlpha(100))
        -- draw the owner on top of it
        love.graphics.polygon('fill', self.polygon)
      else
        love.graphics.setColor(self.ownerColor:getAlpha(200))
        love.graphics.polygon('line', self.innerPolygon)
      end
    end
    
    -- draw all nature objects
    for i,n in pairs(self.nature) do
      if not (self.fog > 0 and n.class < 0) and n.inside == self.viewInside then
        n:draw(self.hover, self.selected, sl, tsl)
      end
    end
    
    -- re-insert particles, if applicable
    for i=1,#self.particleRevive do
      self:checkPosition(self.particleRevive[i])
    end
    self.particleRevive = {}
  end

end

function Region:stopWeather()
  self.weatherStatus = 0
end

function Region:startWeather()
  -- draw weather
  for i=1,30 do
    local p = self:completelyRandomPoint()
    -- destination (x,y), distance from destination (100%), rotation, width, height, speed
    local newP = Particle(-i, p.x, p.y, self.index)
    self:sortedInsert(newP)
  end

end

-- Function that draws a special selection border iff region is selected
function Region:specialDraw()
  if self.fog == 3 then return end
  
  love.graphics.setColor(self.color:getLight())
  love.graphics.setLineWidth(8)
	love.graphics.polygon('line', self.polygon)
end

-- -- -- -- -- -- -- -- -- --[[
-- CONNECTIONS
-- -- -- -- -- -- -- -- -- --]]
-- Adds a neighbour (by index number) to set
function Region:addNeighbour(i)
  table.insert(self.conn, i)
end

-- Sets this region's connections from a list (used for loading)
function Region:setConnections(conn)
  self.conn = conn
end

-- Gets this region's connections
function Region:getConnections()
  return self.conn
end

-- -- -- -- -- -- -- -- -- --[[
-- ADDING & REMOVING OBJECTS
-- -- -- -- -- -- -- -- -- --]]
function Region:addPlant(X, Y, class)
  ID = ID + 1
  
  -- don't place a plant if there's already one close
  for _,n in ipairs(self.nature) do
    if n.class == -1 and math.abs(n:getX() - X) < 15 and math.abs(n:getY() - Y) < 15 then
      return
    end
  end
  
  local p = Plant(ID, X, Y, 0.33, 1, self:getIndex(), 0, -1)
  self:sortedInsert(p)
  EVENTS:addEvent({GROWING_TIME, "naturegrow", p})
end

function Region:addNature(what, owner, x, y, inside)
  local p = {x = x, y = y}
  
  if x == nil and y == nil then
    p = self:randomPoint(what)
  end
  
  if p == nil then
    return
  end
  
  ID = ID + 1
  if what == 'tree' then
    local t = Tree(ID, p.x, p.y, math.prandom(0.75, 1.2), 10, self:getIndex(), 0, p.loc)
    local isAllowed = true
        
    -- remove "hidden"/undesirable locations
    local loco = {}
    if p.idY >= 1 then 
      loco[1] = (p.idY - 1) + p.idX * p.height
      if p.idY >= 2 then
        loco[2] = (p.idY - 2) + p.idX * p.height
        if p.idX >= 1 then
          loco[3] = (p.idY - 2) + (p.idX - 1) * p.height
        end
        if p.idX < p.width then
          loco[4]  = (p.idY - 2) + (p.idX + 1) * p.height
        end
      end
    end
    
    local positions = {}
    
    -- check if any of those hidden locations contains anything; if so, we can't place the tree
    for i=1,#loco do
      if loco[i] ~= nil then
        local r = math.inTable(self.freeLocations, loco[i])
        positions[i] = r
        if not r then
          local s = math.inTable(self.forbiddenLocations, loco[i])
          if not s then
            isAllowed = false
            break
          end
        end
      end
    end
    
    -- if placing the tree is allowed, fill the location(s) and place the tree
    if isAllowed then
      self:fillLocation(p.randLoc)
      
      -- fill all the other locations
      -- done this way because moving indices is an annoying thing to deal with elegantly
      for i=1,#loco do
        for j=1,#self.freeLocations do
          if loco[i] == self.freeLocations[j] then
            self:fillLocation(j)
          end
        end
      end
      
      self.trees = self.trees + 1
      self:sortedInsert(t)
    end
  elseif what == 'stone' then
    local s = Stone(ID, p.x, p.y, math.prandom(0.2, 0.35), 10, self:getIndex(), 0, p.loc)
    self:sortedInsert(s)
    self:fillLocation(p.randLoc)
  elseif what == 'bush' then
    local b = Bush(ID, p.x, p.y, math.prandom(0.24, 0.4), 10, self:getIndex(), 0, p.loc)
    self:sortedInsert(b)
    self:fillLocation(p.randLoc)
  elseif what == 'item' then
    -- owner = subclass (in this case)
    local i = Item(ID, p.x, p.y, 0.1, 10, self:getIndex(), 0, nil, owner, inside)
    self:sortedInsert(i)
  elseif what == 'plant' then
    local p = Plant(ID, p.x, p.y, 0.33, 10, self:getIndex(), 0, p.loc)
    self:sortedInsert(p)
    self:fillLocation(p.randLoc)
  elseif what == 'home' then
    local h = Home(ID, p.x, p.y, math.prandom(0.4, 0.55), self.terrain, 1, self:getIndex(), owner, p.loc)
    h:setResources({0, 0, 0, 0})
    self.building = h
    self:sortedInsert(h)
    self:fillLocation(p.randLoc)
  end
end

function Region:animalBirth(x, y, class, amount, owner, inside, dna1, dna2)
  
  local scaleFromAge = 1 / ANIMAL_PROPS[class][1] * ANIMAL_PROPS[class][2]
  local radius, angle = 5, 0
  
  for i=1,amount do
    local randomGender = true
    if math.prandom(0,1) >= 0.5 then
      randomGender = false
    end
    
    local DNA = math.mixDNA(dna1, dna2)
    
    if class == 1 then
      local b = Bunny(ID, owner, randomGender, 1, x + math.cos(angle)*radius, y + math.sin(angle)*radius, scaleFromAge, 10, 0, self:getIndex(), 1, inside, 10, DNA)
      b:startEvents()
      self:sortedInsert(b)
      EVENTS:addEvent({ONE_YEAR, "age", b})
    end
    
    angle = angle + math.pi / amount
  end
  
end

-- Puts a moving object at the right position - probably resource intensive, so I should find a better way
-- IDEA: Because the array is already sorted, perform a binary search to find the correct position, and insert there
-- IDEA 2: Or, sort the whole array every frame when something's changed, which should be faster if there are lots of animals
-- IDEA 3: Use table.move a few times to drag an element (and we even know the direction we should be looking in)

-- IDEA 4: Lots of times, the position won't change, so we're just wasting time and energy here. Check for that, before removing and inserting again.
function Region:checkPosition(o)
  -- remove element from old position
  for i=1,#self.nature do
    if self.nature[i]:getID() == o:getID() then
      table.remove(self.nature, i)
      break
    end
  end
  
  -- insert it into new one
  self:sortedInsert(o)
end

function Region:sortedInsert(o)
  local i = 1
  while i <= #self.nature do
    if self.nature[i]:getY() >= o:getY() then
      break
    end
    i = i + 1
  end
  table.insert(self.nature, i, o)
end

function Region:addAnimal(a)
  self:sortedInsert(a)
  self.animals = self.animals + 1
  
  -- update the fog
  -- if self:getOwner() ~= a:getOwner() then self:updateFog(0, self.index, REGIONS) end
  if a:getOwner() == 1 then self:updateFog(0, self.index) end
end

function Region:removeAnimal(a)
  -- find the animal in the sorted list, remove it
  for i=1,#self.nature do
    if self.nature[i]:getID() == a:getID() then
      table.remove(self.nature, i)
      break
    end
  end
  
  self.animals = self.animals - 1
  
  -- remove the fog this animal created
  --if self:getOwner() ~= a:getOwner() then self:removeFog(3, self.index, REGIONS) end
  if a:getOwner() == 1 then self:removeFog(3, self.index) end
end

function Region:getNatureWithID(id)
  local n = self.nature
  for i=1,#n do
    if n[i]:getID() == id then
      return n[i]
    end
  end
  
  print("COULDN'T FIND nature with ID?!")
  
  return nil
end

function Region:initializeNature()
  local n = self.nature
  for i=1,#n do
    if n[i].class > 0 then n[i]:initialize() end
  end

end

function Region:setNature(n)
  self.nature = {}
  local temp_id = 0
  
  for i,a in pairs(n) do
    if a.class == -6 then
      table.insert(self.nature, Corpse(a.id, a.owner, a.animalClass, a.x, a.y, a.scale, a.dir, a.region, a.inside, a.meat, a.maxMeat, a.DNA))
    elseif a.class == -5 then
      table.insert(self.nature, Bush(a.id, a.x, a.y, a.scale, a.health, self:getIndex(), a.owner, a.location))
    elseif a.class == -4 then
      table.insert(self.nature, Stone(a.id, a.x, a.y, a.scale, a.health, self:getIndex(), a.owner, a.location))
    elseif a.class == -3 then
      table.insert(self.nature, Tree(a.id, a.x, a.y, a.scale, a.health, self:getIndex(), a.owner, a.location))
    elseif a.class == -2 then
      table.insert(self.nature, Item(a.id, a.x, a.y, a.scale, a.health, self:getIndex(), a.owner, a.location, a.subclass, a.inside))
    elseif a.class == -1 then
      table.insert(self.nature, Plant(a.id, a.x, a.y, a.scale, a.health, self:getIndex(), a.owner, a.location))
    elseif a.class == 0 then
      local h = Home(a.id, a.x, a.y, a.scale, self.terrain, a.health, self:getIndex(), a.owner, a.location)
      h:setResources(a.resources)
      table.insert(self.nature, h)
      self.building = h
    elseif a.class == 1 then
      local b = Bunny(a.id, a.owner, a.gender, a.age, a.x, a.y, a.scale, a.health, a.illness, a.reg, a.terrainModifier, a.inside, a.nutrition, a.DNA)
      b:initializeDestination(a.totalDest, a.dest, a.arrivalAction, a.arrivalActionObject, a.trackingObject)
      b:initializeJob(a.currentJob, a.jobID, a.trackers, a.tracking, a.myGoal, a.attackCountdown)
      b:initializeItem(a.item)
      table.insert(self.nature, b)
    end
    
    if a.id > temp_id then
      temp_id = a.id
    end
  end
  
  -- turn on any weatherEffects
  if self.weatherStatus > 0 then
    self:startWeather()
  end
  
  return temp_id
end

-- -- -- -- -- -- -- -- -- --[[
-- VISIBILITY & HIT-TESTING
-- -- -- -- -- -- -- -- -- --]]

function Region:calculateBoundingBox()
  local minX, maxX, minY, maxY = self.polygon[1], self.polygon[1], self.polygon[2], self.polygon[2]
  local p = self.polygon
  
  -- check X and Y coordinates
  for i=2,#p*0.5 do
    if p[i*2-1] < minX then minX = p[i*2-1] end
    if p[i*2-1] > maxX then maxX = p[i*2-1] end
    if p[i*2] < minY then minY = p[i*2] end
    if p[i*2] > maxY then maxY = p[i*2] end
  end
  
  -- save as bounding box
  self.box = { x1 = minX, x2 = maxX, y1 = minY, y2 = maxY }
end

function Region:calculateInnerPolygon()
  local p = self.polygon
  self.innerPolygon = {}
  
  for i=1,#p*0.5 do
    self.innerPolygon[i*2-1] = (p[i*2-1] - self.centroid.x) * 0.8 + self.centroid.x
    self.innerPolygon[i*2] = (p[i*2] - self.centroid.y) * 0.8 + self.centroid.y
  end
end

function Region:calculateGroundLines() 
  -- generate underground interior of region
  local p = self.innerPolygon
  local depth = 4
  local nP = #p
  for i=1,nP*0.5 do
    local x1, y1, x2, y2 = p[i*2-1], p[i*2] + depth, p[math.mod(i*2+1, nP)], p[math.mod(i*2+2, nP)] + depth
    local h1 = self:generalHitTest(x1, y1, p)
    local h2 = self:generalHitTest(x2, y2, p) 
    
    if h1 or h2 then
      
      local X1,Y1,X2,Y2 = x1, y1, x2, y2
      if not h1 then
        X1,Y1 = math.performIntersect(x1, y1, x2, y2, x1, y1 - depth, p[math.mod(i*2-3, nP)], p[math.mod(i*2-2, nP)])
        if X1 == -1 then X1,Y1 = x1, y1 end
      elseif not h2 then
        X2,Y2 = math.performIntersect(x1, y1, x2, y2, x2, y2 - depth, p[math.mod(i*2+3, nP)], p[math.mod(i*2+4, nP)])
        if X2 == -1 then X2,Y2 = x2, y2 end
      end
      
      self:addGroundLine({x1, y1 - depth, x2, y2 - depth, X2, Y2, X1, Y1})
    end
  end
end

-- Checks whether this region is visible 
-- by checking if its bounding box is inside camera bounding box
function Region:checkVisibility(bounds)
  if (bounds.x2 < self.box.x1 or self.box.x2 < bounds.x1 or bounds.y2 < self.box.y1 or self.box.y2 < bounds.y1) then
    self.visible = false
  else
    self.visible = true
  end
end

function Region:checkDistance(x, y)
  if (x < self.box.x1 or self.box.x2 < x or y < self.box.y1 or self.box.y2 < y) then
    return false
  end
  return true
end

--[[ 
Tests whether a certain point (X,Y) is within this region's polygon

We loop through all vertices of the polygon, and define i and j as subsequent vertices (and therefore connected by an edge of the polygon)
Then we perform two checks:
  -> Whether two subsequent vertices are on different sides of our chosen point in the Y-direction
  -> Whether two subsequent vertices are on different sides of our chosen point in the X-direction
If both are true, we just added a line that changed the status of our point - if it was inside at first, it's now outside, and vice versa.

NOTE: Polygon is saved as x, y, x, y, x, y

Third parameter signifies whether we're cursor hittesting or not
--]]
function Region:hitTest(X, Y)
  if not self:checkDistance(X, Y) then
    return false
  end
  
  return self:generalHitTest(X,Y,self.polygon)
end

function Region:generalHitTest(X,Y,p) 
  local c = false
  local j = #p*0.5
  for i=1,#p*0.5 do
    if (p[2*i] > Y) ~= (p[2*j] > Y) then
      if X < (p[2*j-1] - p[2*i-1]) * (Y - p[2*i]) / (p[2*j] - p[2*i]) + p[2*i-1] then
        c = not c
      end
    end
    j = i
  end

  return c
end

function Region:completelyRandomPoint()
  local rX, rY = math.prandom(self.box.x1, self.box.x2), math.prandom(self.box.y1, self.box.y2)
  local tries = 0
  
  while not self:generalHitTest(rX, rY, self.innerPolygon) do
    rX, rY = math.prandom(self.box.x1, self.box.x2), math.prandom(self.box.y1, self.box.y2)
    tries = tries + 1
    
    if tries >= 20 then
      rX, rY = self.centroid.x, self.centroid.y
      break
    end
  end
  
  return {x = rX, y = rY}
end

function Region:randomPoint(what)
  -- no free locations, no random point
  if #self.freeLocations < 2 and what ~= "home" then
    return nil
  end
  
  local width = math.round( (self.box.x2 - self.box.x1) / REGION_SQUARE )
  local rectW = (self.box.x2 - self.box.x1) / width
  local height = math.round( (self.box.y2 - self.box.y1) / REGION_SQUARE )
  local rectH = (self.box.y2 - self.box.y1) / height
  
  local margin = 5
  
  -- if there's no space, but we really need to build a home, remove something else!
  if what == "home" and #self.freeLocations < 1 then
    print("Had to delete nature to make room for home")
    -- go through nature, find first thing that is removable, make it die
    for i,n in pairs(self.nature) do
      if n.class < 0 then
        n:die()
        break
      end
    end
  end
  
  -- get random location
  local randLoc = math.round(math.prandom(1, #self.freeLocations))
  local loc = self.freeLocations[randLoc]
  local idX = math.floor(loc / height)
  local idY = loc % height
  
  -- get random point within location
  local pX = self.box.x1 + math.prandom(idX * rectW + margin, (idX + 1) * rectW - margin * 2)
  local pY = self.box.y1 + math.prandom(idY * rectH + margin, (idY + 1) * rectH - margin * 2)
  
  -- return position + location
  return {x = pX, y = pY, loc = loc, width = width, height = height, randLoc = randLoc, idX = idX, idY = idY}
end

function Region:fillLocation(i)
  table.remove(self.freeLocations, i)
end

function Region:fillLocations(arr)
  local removals = 0
  for i=1,#arr do
    if arr[i] ~= false then
      table.remove(self.freeLocations, arr[i] - removals)
      removals = removals + 1
    end
  end
end

function Region:checkCircleDistance(x1, y1, x2, y2, r)
  return (x1 - x2)^2 + (y1 - y2)^2 < r^2
end

function Region:hitTestNature(X, Y)
  local obj, obj2 = nil, nil
  
  -- HITTEST EVERYTHING!
  for i=#self.nature,1,-1 do
    local n = self.nature[i]
    local condition = (not CAMERA:checkScaleLine() and n.alpha == 255 and n.class ~= 7) or (CAMERA:checkScaleLine() and n.class > 0) 
    if condition and (n.inside == self.viewInside) then
      local result = n:hitTest(X, Y)
      if result then
        obj = n
        break
      end
    end
  end
  
  -- HITTEST NEIGHBOURS TO BE SURE
  -- but only those with a lower y-value
  for i=1,#self.conn do
    local nei = REGIONS[self.conn[i]]
    if nei.centroid.y >= self.centroid.y then
      for j=#nei.nature,1,-1 do
        local n = nei.nature[j]
        local condition = (not CAMERA:checkScaleLine() and n.alpha == 255 and n.class ~= 7) or (CAMERA:checkScaleLine() and n.class > 0)
        if condition and (n.inside == self.viewInside) then
          local result = n:hitTest(X, Y)
          if result then
            obj2 = n
            break
          end
        end
      end
    end
  end
  
  if obj2 ~= nil and (obj1 == nil or obj2.y > obj.y) then 
    return obj2 
  end
  
  return obj
end

function Region:calculateFreeLocations()

  -- calculate possible locations
  local width = math.round( (self.box.x2 - self.box.x1) / REGION_SQUARE )
  local rectW = (self.box.x2 - self.box.x1) / width
  local height = math.round( (self.box.y2 - self.box.y1) / REGION_SQUARE )
  local rectH = (self.box.y2 - self.box.y1) / height
  
  -- go through all locations
  for i=0, (width - 1) do
    for j=0, (height - 1) do
      -- calculate start and end points of rectangle
      local box = {self.box.x1 + rectW * i, self.box.y1 + rectH * j, self.box.x1 + rectW * (i + 1), self.box.y1 + rectH * (j+1)}
      
      -- check all points; if at least one of them is outside the polygon, this rectangle is disqualified
      if not self:generalHitTest(box[1], box[2], self.polygon) or 
         not self:generalHitTest(box[3], box[2], self.polygon) or
         not self:generalHitTest(box[3], box[4], self.polygon) or
         not self:generalHitTest(box[1], box[4], self.polygon) then
           -- why this structure? because Lua doesn't need to check all points this way
        table.insert(self.forbiddenLocations, i * height + j)
      else
        -- this location is possible, insert it (by unique ID)
        table.insert(self.freeLocations, i * height + j)
      end
      
    end
  end
end

function Region:calculateNeighbourLines()
  
  -- for all neighbours
  for _,c in ipairs(self.conn) do
    -- check which edge connects to them
    local p = self.polygon
    local p2 = REGIONS[c].polygon
    
    local saveStart = 0
    local saveEnd = 0
    
    -- for all our points
    for i=1,#p*0.5 do
      
      -- check against all neighbour points
      for j=1,#p2*0.5 do
        
        -- we've found a matching point!
        if p[i*2-1] == p2[j*2-1] and p[i*2] == p2[j*2] then
          -- if it's the first match, it is the start of our line
          -- otherwise, it's the end and we can stop looking
          if saveStart == 0 then 
            saveStart = i
          else
            saveEnd = i
          end
          break
        end
      end
      
      if saveEnd > 0 then
        break
      end
    end
    
    -- save the line using the neighbour's index as table index
    self.connLines[c] = {p[saveStart*2-1], p[saveStart*2], p[saveEnd*2-1], p[saveEnd*2]}
    
    -- remove "wrong lines" that occur 
    if #self.connLines[c] < 4 then
      print("Wrong line at: " .. self.index)
      self.connLines[c] = nil
    end
  end
end

-- -- -- -- -- -- -- -- -- --[[
-- PATH FINDING
-- -- -- -- -- -- -- -- -- --]]
function Region:setPathDist(v)
  self.pathDist = v
end

function Region:getPathDist()
  return self.pathDist
end

function Region:setPathPrev(r)
  self.pathPrev = r
end

function Region:getPathPrev()
  return self.pathPrev
end

function Region:setPathUsed(b)
  self.pathUsed = b
end

function Region:getPathUsed()
  return self.pathUsed
end

function Region:getImpassable()
  return (self.terrain <= 3)
end

function Region:calcPathDist(r, targ)
  -- basic distance
  local dx = self.centroid.x - r.centroid.x
  local dy = self.centroid.y - r.centroid.y
  local D = 1
  if r:getTerrain() >= 7 then
    D = 40000
  end
  local sum = D * (dx * dx + dy * dy)
  
  -- heuristic (distance weighs heavier than terrain)
  dx = self.centroid.x - targ.centroid.x
  dy = self.centroid.y - targ.centroid.y
  
  return sum + 1000 * (dx * dx + dy * dy)
end

-- A*, but actually Dijkstra with a heuristic to speed it up
-- target is the target _region_
-- X,Y are the actual _mouseclick_ coordinates
-- X2, Y2 are the actual _starting_ coordinates
function Region:pathFind(target, X, Y, X2, Y2) 
  local count = #REGIONS
  local INF = 1/0
  
  -- if target can't be reached in any possible way, we don't even need to bother pathfinding
  if target:getImpassable() then
    return nil
  end
  
  -- if target is the same as start (region), we can just go in a straight line
  if target.index == self.index then
    return {}
  end
  
  -- initialize all regions (set all to infinite distance, remove impassable ones)
  for i,r in pairs(REGIONS) do
    r:setPathDist(INF)
    r:setPathUsed(r:getImpassable())
    r:setPathPrev(nil)
  end
  
  -- set starting region to distance 0
  self:setPathDist(0)
  
  -- while we still have regions left to process
  while count > 0 do
    -- find vertex with minimum distance
    local min_dist = INF
    local min_reg = nil
    local min_index = 1
    
    -- check all neighbours, if not already checked, assign new (minimum) distance
    for i,r in pairs(REGIONS) do
      if not r:getPathUsed() then
        local d = r:getPathDist()
        if d < min_dist then
          min_dist = d
          min_reg = r
          min_index = i
        end
      end
    end
    
    -- if there's no path possible
    if min_reg == nil then
      return nil
    end
    
    -- stop searching altogether if we've found our target
    if min_reg.index == target.index then
      break
    end
    
    -- remove the region we just checked from list of vertices
    count = count - 1
    min_reg:setPathUsed(true)

    -- update the connections of the chosen vertex (if they are still in Q)
    for i,c in pairs(min_reg:getConnections()) do
      local c2 = REGIONS[c]
      
      if not c2:getPathUsed() then
        -- calculate distance
        local new_dist = min_reg:getPathDist() + min_reg:calcPathDist(c2, target)
        
        -- update distance and predecessor, but only if new distance is less than current
        if new_dist < c2:getPathDist() then
          c2:setPathDist(new_dist)
          c2:setPathPrev(min_reg)
        end
      end
    end
  end
  
  -- if we found a path (aka, the algorithm terminated without exhausting all regions)
  if count > 0 then
    -- retrace our steps
    local PATH = {}
    local prevPrev, prev3 = nil, nil
    local curPrev = target
    local lastPoint = {X,Y}
    
    prevPrev = curPrev
    curPrev = curPrev:getPathPrev()

    local c = prevPrev.connLines[curPrev.index]
    table.insert(PATH, 1, {math.performIntersect(curPrev.centroid.x, curPrev.centroid.y, X, Y, c[1], c[2], c[3], c[4])})
    
    local debugCounter = 0
    
    while curPrev:getIndex() ~= self:getIndex() do
      prev3 = prevPrev
      prevPrev = curPrev
      curPrev = curPrev:getPathPrev()
      
      -- calculate right point on edge line
      c = prevPrev.connLines[curPrev.index]
      table.insert(PATH, 1, {math.performIntersect(prevPrev.centroid.x, prevPrev.centroid.y, curPrev.centroid.x, curPrev.centroid.y, c[1], c[2], c[3], c[4])})
      
      -- now that we know the closest point on edge line, re-calculate previous point
      c = prev3.connLines[prevPrev.index]
      PATH[2] = {math.performIntersect(PATH[1][1], PATH[1][2], lastPoint[1], lastPoint[2], c[1], c[2], c[3], c[4])}
      lastPoint = PATH[2]
      
      -- fixes an annoying crash issue, but
      -- TO DO: Find the actual solution to the problem, instead of just quitting the loop when I feel like it
      debugCounter = debugCounter + 1
      if debugCounter > 10 then
        break
      end
    end
    
    -- override first destination to account for actual animal position at start (WRONG! with the new algorithm)
    --c = prevPrev.connLines[curPrev.index]
    --PATH[1] = {math.performIntersect(PATH[1][1], PATH[1][2], X2, Y2, c[1], c[2], c[3], c[4])}
  
    return PATH
  else
    return nil
  end
end
