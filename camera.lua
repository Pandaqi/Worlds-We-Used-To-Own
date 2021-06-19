
Camera = Object:extend()

function Camera:new(x, y, scale, speed, bounds)
  self.x = x
  self.y = y
  self.scale = scale
  self.speed = speed
  self.worldBounds = bounds
  self.windowBounds = { width = 0, height = 0}
  self.scaleBounds = { max = 1, min = 1}
  self.changed = true
  self.myStencilTable = {}
  
  self:updateBounds()
end

-- Whenever the game is resized, the world automatically updates
function Camera:updateBounds()
  -- Update scale parameters and camera view bounds
  love.graphics.reset()
  self.windowBounds.width = love.graphics.getWidth()
  self.windowBounds.height = love.graphics.getHeight()
  self.scaleBounds.min = 0.04
  self.scaleBounds.max = math.min(self.worldBounds.width / self.windowBounds.width, self.worldBounds.height / self.windowBounds.height)
  
  -- Move the camera to make up for lost/gained space
  self:scaleRelative(1)
  self:move(0,0)
  
  -- Update GUI
  GUI:updateBounds(self.windowBounds.width, self.windowBounds.height)
end

function Camera:getMapData()
  return self.worldBounds
end

function Camera:getSaveData()
  return {self.x, self.y, self.scale}
end

-- Function that registers input to move camera around
function Camera:detectInput()
  -- move camera horizontally
  if love.keyboard.isDown("a") then
    self:move(-1,0)
  elseif love.keyboard.isDown("d") then
    self:move(1,0)
  end
  
  -- move camera vertically
  if love.keyboard.isDown("w") then
    self:move(0, -1)
  elseif love.keyboard.isDown("s") then
    self:move(0, 1)
  end
  
  -- zoom out and zoom in
  if love.keyboard.isDown("q") then
    self:scaleRelative(1.02)
  elseif love.keyboard.isDown("e") then
    self:scaleRelative(0.98)
  end
  
  -- flag if we changed view, so we need to update regions
  if self.changed then
    self.changed = false
    return true
  else
    return false
  end
end

-- Converts global mouse position into in-world mouse position
function Camera:getMousePosition() 
  local X, Y = love.mouse.getPosition()
  return self.x + X * self.scale, self.y + Y * self.scale
end

function Camera:getMousePositionObject(X, Y)
  return {x = self.x + X * self.scale, y = self.y + Y * self.scale}
end

-- Gets bounding box of camera, for easy clipping
function Camera:getBoundingBox()
  return { x1 = self.x, x2 = self.x + self.windowBounds.width * self.scale, y1 = self.y, y2 = self.y + self.windowBounds.height * self.scale }
end

-- Transforms the canvas for current camera settings
function Camera:set()
  love.graphics.push()
  love.graphics.scale(1.0 / self.scale, 1.0 / self.scale)
  love.graphics.translate(-self.x, -self.y)
end

-- Restores canvas settings
function Camera:unset()
  love.graphics.pop()
end

-- Moves the camera relative to current position
function Camera:move(dx, dy)
  dx = dx * self.speed * self.scale
  dy = dy * self.speed * self.scale
  self.x = math.clamp(0, self.x + dx, self.worldBounds.width - self.windowBounds.width * self.scale)
  self.y = math.clamp(0, self.y + dy, self.worldBounds.height - self.windowBounds.height * self.scale)
  self.changed = true
end

-- Scales the camera relative to current scale
function Camera:scaleRelative(s)
  local X, Y = self:getMousePosition()
  local X2, Y2 = love.mouse.getPosition() 
  self.scale = math.clamp(self.scaleBounds.min, self.scale * s, self.scaleBounds.max)
  self:setPosition( X - (X2 * self.scale), Y - (Y2 * self.scale) )
  self.changed = true
end

-- Sets the absolute position of the camera
function Camera:setPosition(x, y)
  self.x = math.clamp(0, x, self.worldBounds.width - self.windowBounds.width * self.scale)
  self.y = math.clamp(0, y, self.worldBounds.height - self.windowBounds.height * self.scale)
  self.changed = true
end

-- Sets the absolute scale of the camera
function Camera:setScale(s)
  self.scale = math.clamp(self.scaleBounds.min, s, self.scaleBounds.max)
  self.changed = true
end

function Camera:getScale()
  return self.scale
end

function Camera:checkScaleLine()
  return self.scale > 0.75
end

function Camera:checkTopScaleLine()
  return self.scale > 1.5
end

function Camera:checkSightLine(y)
  return y > self.y + 0.8 * self.windowBounds.height * self.scale
end

-- FOR STENCIL TESTS (aka lights and shadows)
function Camera:addToStencil(o)
  self.myStencilTable[#self.myStencilTable+1] = {o.x, o.y, o.scale}
end

function Camera:lightStencil()
  local t = self.myStencilTable
  
  -- go through all light emitters in the scene
  for i=1,#t do
    local t2 = t[i]
    local tX, tY = (t2[1] - self.x) / self.scale, (t2[2] - self.y) / self.scale
    local rad = t2[3] / self.scale * 150
    
    love.graphics.ellipse('fill', tX, tY, rad, rad)
  end
  
  -- reset stencil table
  self.myStencilTable = {}
end