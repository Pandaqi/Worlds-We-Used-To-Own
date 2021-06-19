
Corpse = Object:extend()

function Corpse:new(id, owner, animalClass, x, y, scale, dir, region, inside, meat, maxMeat, DNA)
  self.id = id
  self.owner = owner
  self.class = -6
  self.animalClass = animalClass
  
  self.x = x
  self.y = y
  self.scale = scale
  self.dir = dir
  self.DNA = DNA
  
  -- for completeness
  self.alpha = 255
  self.health = 1
  
  if animalClass == 1 then
    self.center = {50, 88}
    self.shadow = {50, 88, 45, 10}
    self.eyes = {32, 33}
    self.bodyShadow = {34, 35, 36, 37}
  end
  
  self.bodyPoly = CORPSE_POLYGONS[animalClass][1]
  self.outlinePoly = CORPSE_POLYGONS[animalClass][2]
  self.outlinePolyTriangles = CORPSE_POLYGONS[animalClass][3]
  
  local myFurColour = ANIMAL_COLOUR_MAP[animalClass]
  if self.DNA[9][1] == 0 and self.DNA[9][2] == 0 then
    myFurColour = Color(ANIMAL_COLOUR_MAP[animalClass]:getDark())
  end
  
  local myEyeColour = Color(110, 110, 110)
  if self.DNA[10][1] == 0 and self.DNA[10][1] == 0 then
    myEyeColour = Color(240, 120, 120)
  end
  
  self.colors = {}
  for i=1,#self.bodyPoly do
    if math.inTable(self.eyes, i) then
      self.colors[i] = Color(myEyeColour:getDesaturatedDark())
    elseif math.inTable(self.bodyShadow, i) then
      self.colors[i] = Color(50, 50, 50, 150)
    else
      self.colors[i] = Color(myFurColour:getDesaturatedDark()):getRandom()
    end
  end
  
  self.region = region
  self.inside = inside
  self.meat = meat
  self.maxMeat = maxMeat
end

function Corpse:updateHealth()
  self.meat = self.meat - 1
  
  if self.meat <= 0 then
    self:die()
    return true
  end
  
  return false
end

function Corpse:die()
  REGIONS[self.region]:addToRemovalQueue(self)
end

function Corpse:clean()
  self.center = nil
  self.shadow = nil
  
  self.outlinePoly = nil
  self.outlinePolyTriangles = nil
  self.bodyPoly = nil
end

function Corpse:getY()
  return self.y
end

function Corpse:getX()
  return self.x
end

function Corpse:getID()
  return self.id
end

function Corpse:getClass()
  return self.class
end

function Corpse:getRegion()
  return self.region
end

function Corpse:unHover()
  self.hover = false
end

function Corpse:doHover()
  self.hover = true
end

-- don't know what to do with selecting/deselecting for now
function Corpse:selectAction()
  return
end

function Corpse:deselectAction()
  return
end

function Corpse:specialDraw()
  return
end

function Corpse:getRandomPointAround()
  local X,Y = self:getX() + math.prandom(-35 * self.scale, 35 * self.scale), self:getY() + math.prandom(1,5)
  
    -- if this leads to a destination outside of target region, change it
  while not REGIONS[self.region]:generalHitTest(X, Y, REGIONS[self.region].polygon) do
    X,Y = self:getX() + math.prandom(-35 * self.scale, 35 * self.scale), self:getY() + math.prandom(1,5)
  end
  
  return X,Y
end

-- -- -- -- -- -- -- -- -- --[[
-- DRAWING (animal + shadow)
-- -- -- -- -- -- -- -- -- --]]
function Corpse:draw()
  love.graphics.push()
  
  -- scales and translates the canvas to where the animal should be
  love.graphics.scale(self.scale * self.dir, self.scale)
  love.graphics.translate(self.graphicTranslationX, self.graphicTranslationY)

  -- if we're zoomed out, only draw outline
  if CAMERA:checkScaleLine() then
    
    love.graphics.setColor(ANIMAL_COLOUR_MAP[self.animalClass]:get())
    love.graphics.setLineWidth(10)
    love.graphics.polygon('line', self.outlinePoly)
    
  -- otherwise, draw the whole thing
  else    
    
    -- creates every polygon, using the randomly generated colours   
    
    for i=1,#self.bodyPoly do
      love.graphics.setColor(self.colors[i]:get())
      love.graphics.polygon('fill', self.bodyPoly[i])
    end
    
    local c = COLOUR_MAP[self.owner]
    love.graphics.setColor(c:get())
    
    -- visual feedback for hovering
    if self.hover then
      love.graphics.setColor(COLOUR_MAP[self.owner]:get())
      for i=1,#self.outlinePolyTriangles do
        love.graphics.polygon('fill', self.outlinePolyTriangles[i])
      end
          
      -- display health bar (flip to right direction)
      local startX, endX = 0, 100 * self.meat/self.maxMeat
      if self.dir == -1 then
        startX = 100
        endX = -endX
      end
      
      love.graphics.rectangle('fill', startX, -10, endX, 10)
      love.graphics.rectangle('line', startX, -10, endX, 10)
      
      love.graphics.setColor(c:getAlpha(50))
      love.graphics.rectangle('fill', 0, -10, 100, 10)
    end
  end
  
  -- restores the canvas to previous position
  love.graphics.pop()
end

-- v is true if the animal is currently visible, and thus shadow also visible
function Corpse:shadowDraw(v)
  self.graphicTranslationX = self.x * (1 / self.scale) - self.center[1]
  self.graphicTranslationY = self.y * (1 / self.scale) - self.center[2]
  
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

function Corpse:hitTest(X,Y)    
  X = X - self.x + self.center[1]*self.scale
  Y = Y - self.y + self.center[2]*self.scale
  
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