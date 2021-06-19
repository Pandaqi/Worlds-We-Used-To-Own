
Particle = Object:extend()

function Particle:new(id, x, y, region)
  self.id = id
  self.region = region
  
  self:initialize(x, y)
end

function Particle:initialize(x, y)
  self.lifeSpan = 1
  
  self.class = -7
  
  self.x = x
  self.y = y
  
  self.state = 0
  self.inside = false
  
  self.subclass = REGIONS[self.region].weatherStatus
  
  if self.subclass == 1 then
    self.rot = math.prandom(0.35, 0.4) * math.pi
    local w = math.prandom(3,9)
    local h = math.prandom(0.5, 1)
  
    self.colors = {Color(150, 150, 255), Color(100, 150, 180)}
    self.maxState = 2
    self.polygon = {math.cos(self.rot) * w, math.sin(self.rot) * w, math.cos(self.rot - 0.5*math.pi) * h, math.sin(self.rot - 0.5*math.pi) * h}
    
    self.speed = math.prandom(0.02, 0.04)
  elseif self.subclass == 2 then
    self.rot = math.prandom(0.35, 0.65) * math.pi
    local s = math.prandom(1,3)
    
    self.colors = {Color(225, 225, 225), Color(255, 255, 255)}
    self.maxState = 2
    self.polygon = {s, s, -s, s}
    
    self.speed = math.prandom(0.002, 0.004)
  elseif self.subclass == 3 then
    self.rot = math.prandom(0.025, -0.025) * math.pi
    local w = math.prandom(3,16)
    local h = math.prandom(0.5, 1)
  
    self.colors = {Color(245, 222, 179)}
    self.maxState = 1
    self.polygon = {math.cos(self.rot) * w, math.sin(self.rot) * w, math.cos(self.rot - 0.5*math.pi) * h, math.sin(self.rot - 0.5*math.pi) * h}
    
    self.speed = math.prandom(0.02, 0.04)
  end
end

function Particle:getY()
  return self.y
end

function Particle:getClass()
  return self.class
end

function Particle:specialDraw()
  return
end

function Particle:shadowDraw()
  return
end

function Particle:getID()
  return self.id
end

function Particle:isNature()
  return false
end

function Particle:draw(h, s, sl, tsl)
  if sl or self.subclass == 0 then
    return
  end
  
  if self.state == 0 then
    love.graphics.setColor(self.colors[1]:getAlpha(175))
    -- otherwise draw the particle, and move it towards its destination point (on the ground)
    local x = self.x + math.cos(self.rot) * self.lifeSpan * 100
    local y = self.y - math.sin(self.rot) * self.lifeSpan * 100
    local p = self.polygon
    
    love.graphics.polygon('fill', {x, y, x + p[1], y - p[2], x + p[1] + p[3], y - p[2] - p[4], x + p[3], y - p[4]})
  elseif self.state == 1 then
    love.graphics.setColor(self.colors[2]:getAlpha(50 - (1 - self.lifeSpan) * 50))
    love.graphics.ellipse('fill', self.x, self.y, (1 - self.lifeSpan*self.lifeSpan) * 10, (1 - self.lifeSpan*self.lifeSpan) * 3)
  end
  
  self.lifeSpan = self.lifeSpan - self.speed
  if self.lifeSpan <= 0 then
    self.lifeSpan = 1
    self.state = self.state + 1
  end
  
  if self.state >= self.maxState then
    local reg = REGIONS[self.region]
    if reg.weatherStatus > 0 then
      -- re-initialize particle, order the "owner region" to insert it into the right position again
      local p = reg:completelyRandomPoint()
      self:initialize(p.x, p.y)
      reg.particleRevive[#reg.particleRevive + 1] = self
    else
      -- remove the particle, FOREVER
      reg:addToRemovalQueue(self)
    end
  end
end