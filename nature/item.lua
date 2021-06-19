
Item = Nature:extend()

function Item:new(id, x, y, scale, health, region, owner, location, subclass, inside)
  Item.super.new(self, id, x, y, scale, health, region, owner, location)
  
  self.class = -2
  -- SUBCLASSES: 1 = seed, 2 = leaf, 3 = branch, 4 = stone
  self.subclass = subclass
  self.inside = inside
  
  self.maxHealth = 10
  self.taken = false
  
  self.polygons = { ITEM_POLYGONS[subclass] }
  
  if subclass == 1 then
    self.shadow = {50, 64, 40, 15}
    self.center = {50, 71}
    self.centerCarried = {44, 28}
    self.scale = math.prandom(0.015, 0.03)
  elseif subclass == 2 then
    self.shadow = {44, 62, 40, 15}
    self.center = {44, 66}
    self.centerCarried = {43, 31}
    self.scale = math.prandom(0.015, 0.04)
  elseif subclass == 3 then
    self.shadow = {50, 54, 40, 10}
    self.center = {70, 61}
    self.centerCarried = {50, 43}
    self.polygons = ITEM_POLYGONS[subclass]
    self.scale = math.prandom(0.02, 0.07)
  elseif subclass == 4 then
    self.shadow = {50, 66, 48, 15}
    self.center = {50, 72}
    self.centerCarried = {50, 35}
    self.scale = math.prandom(0.02, 0.07)
  end
  
  self.itemWeight = subclass * self.scale
  
  self.outlinePolygon = ITEM_OUTLINE_POLYGONS[subclass]
  self.fillPolygon = ITEM_FILL_POLYGONS[subclass]
  
  self.mainColours = ITEM_COLOURS[subclass]
  
  self:colorization()

end

function Item:setTaken(val)
  self.taken = val
end

function Item:getName()
  return "BITEM"
end

function Item:itemDraw(ownerX, ownerY, ownerScale, ownerDir)
  love.graphics.push()
  love.graphics.scale(self.scale * ownerDir, self.scale)
  local transX = ownerX * (1 / self.scale) + self.x * (ownerScale / self.scale) - self.centerCarried[1]
  local transY = ownerY * (1 / self.scale) + self.y * (ownerScale / self.scale) - self.centerCarried[2]
  love.graphics.translate(transX, transY)
  
  for p=1,#self.polygons do
    local pol = self.polygons[p]
    for i=1,#pol do
      love.graphics.setColor(self.colors[p][i]:get())
      love.graphics.polygon('fill', self.polygons[p][i])
    end
  end
  
  love.graphics.pop()
end