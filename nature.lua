
Nature = Object:extend()

function Nature:new(id, x, y, scale, health, region, owner, location)
  self.id = id
  
  self.x = x
  self.y = y
  self.scale = scale
  
  self.health = health
  
  self.hover = false
  self.inside = false
  self.region = region
  self.owner = owner
  
  self.alpha = 255
    
  self.growthPlanned = false
  self.windOffset = 0
  
  self.location = location
  
  -- increment global ID counter
  ID = ID + 1
end

function Nature:colorization() 
  self.colors = {}

  for p=1,#self.polygons do
    local pol = self.polygons[p]
    table.insert(self.colors, {})
    for i=1,#pol do
      self.colors[p][i] = self.mainColours[p]:getRandom()
    end
  end
end

function Nature:getClass()
  return self.class
end

function Nature:getX()
  return self.x
end

function Nature:getY()
  return self.y
end

function Nature:getID()
  return self.id
end

function Nature:getOwner()
  return self.owner
end

function Nature:getRegion()
  return self.region
end

-- don't know what to do with selecting/deselecting for now
function Nature:selectAction()
  return
end

function Nature:deselectAction()
  return
end

function Nature:specialDraw()
  return
end

-- h is true if currently hovering over this region
-- s is true if region is currently selected

-- sl is true if scaleline is reached (aka camera distance is large enough)
-- tsl is true if topscaleline is reached
function Nature:draw(h, s, sl, tsl)
  if tsl then return end
  
  love.graphics.push()
  
  -- scales and translates the canvas to where the animal should be
  love.graphics.scale(self.scale, self.scale)
  love.graphics.translate(self.graphicTranslationX, self.graphicTranslationY)
  
  -- if h then alpha = 50 end
  if CAMERA:checkSightLine(self.y) then 
    self.alpha = 50 
  else 
    self.alpha = 255 
  end

  -- if we're zoomed out, only draw outline
  if sl then
    if self.class < -2 or self.class == 0 then
      love.graphics.setColor(self.mainColours[1]:get())
      love.graphics.setLineWidth(1)
      love.graphics.polygon('line', self.outlinePolygon)
    end
      
  -- otherwise, draw the whole thing
  else
  
    love.graphics.setShader(EVENTS.windShader)
    self.windOffset = math.sin(EVENTS.time + self.id)
    EVENTS.windShader:send("offset", self.windOffset)
    EVENTS.windShader:send("pivot", self.center[2])
  
    for p=1,#self.polygons do
      local pol = self.polygons[p]
      for i=1,#pol do
        love.graphics.setColor(self.colors[p][i]:getAlpha(self.alpha))
        love.graphics.polygon('fill', self.polygons[p][i])
      end
    end

    if self.hover then
      love.graphics.setColor(100, 255, 100)
      for i=1,#self.fillPolygon do
        love.graphics.polygon('fill', self.fillPolygon[i])
      end
      
      -- display health
      love.graphics.setColor(0,0,0,50)
      love.graphics.rectangle('fill', 0, 0, 100, 5)
      
      love.graphics.setColor(0,0,0)
      love.graphics.rectangle('fill', 0, 0, 100 * self.health / self.maxHealth, 5)
      love.graphics.rectangle('line', 0, 0, 100 * self.health / self.maxHealth, 5)
    end
    
    love.graphics.setShader()
    
  end
  
  -- restores the canvas to previous position
  love.graphics.pop()
end

function Nature:shadowDraw(v, sl, tsl)
  if tsl then return end
  
  self.graphicTranslationX = self.x * (1 / self.scale) - self.center[1]
  self.graphicTranslationY = self.y * (1 / self.scale) - self.center[2]
  
  if sl or self.alpha < 255 then return end
  
  love.graphics.push()
  
  love.graphics.scale(self.scale, self.scale)
  love.graphics.translate(self.graphicTranslationX, self.graphicTranslationY)
  
  -- creates shadow
  love.graphics.setColor(0, 0, 0, 80)
  love.graphics.ellipse('fill', self.shadow[1], self.shadow[2], self.shadow[3], self.shadow[4])
  
  love.graphics.pop()
end

function Nature:clean()
  self.colors = nil
  self.polygons = nil
  self.mainColours = nil
  self.outlinePolygon = nil
  self.fillPolygon = nil
  self.shadow = nil
  self.center = nil
  
  self.graphicTranslationX = nil
  self.graphicTranslationY = nil
end

function Nature:unHover()
  self.hover = false
end

function Nature:doHover()
  self.hover = true
end

function Nature:hitTest(X,Y)    
  X = X - self.x + self.center[1]*self.scale
  Y = Y - self.y + self.center[2]*self.scale
  
  local c = false
  local p = self.outlinePolygon
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

function Nature:getHealth()
  return self.health
end

function Nature:getMaxHealth()
  return self.maxHealth
end

function Nature:updateHealth(dh)
  self.health = self.health + dh
  
  if self.health >= self.maxHealth then
    self.health = self.maxHealth
    return false
  elseif self.health <= 0 then
    return false
  end
  
  return true
end

function Nature:isInside()
  return self.inside
end

function Nature:isNature()
  return (self.class ~= -2)
end

function Nature:die()
  REGIONS[self.region]:addToRemovalQueue(self)
end

function Nature:dropItem(subclass)
  local X, Y = self:getRandomPointAround()
  REGIONS[self.region]:addNature('item', subclass, X, Y, self.inside)
end

function Nature:hasResource(targets)
  if self.class == -5 then
    if math.inTable(targets, 2) or math.inTable(targets, 3) then
      return true
    end
  else
    if math.inTable(targets, self.subclass) then
      return true
    end
  end
  return false
end

function Nature:getRandomPointAround()
  local X,Y = self:getX() + math.prandom(-35 * self.scale, 35 * self.scale), self:getY() + math.prandom(1,5)
  
    -- if this leads to a destination outside of target region, change it
  while not REGIONS[self.region]:generalHitTest(X, Y, REGIONS[self.region].polygon) do
    X,Y = self:getX() + math.prandom(-35 * self.scale, 35 * self.scale), self:getY() + math.prandom(1,5)
  end
  
  return X,Y
end