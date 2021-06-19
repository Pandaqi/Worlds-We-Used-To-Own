
Stone = Nature:extend()

function Stone:new(id, x, y, scale, health, region, owner, location)
  Stone.super.new(self, id, x, y, scale, health, region, owner, location)
  
  self.class = -4
  self.subclass = 4
  
  self.maxHealth = 10
  
  self.shadow = {50, 71, 40, 10}
  self.center = {50, 71}
  
  self.polygons = { STONE_POLYGON }
  self.outlinePolygon = STONE_OUTLINE_POLYGON
  self.fillPolygon = STONE_FILL_POLYGON
  
  self.mainColours = { STONE_COLOUR }
  
  self:colorization()
end

function Stone:updateHealth(dh)
  local r = Stone.super.updateHealth(self, dh)
  
  if dh < 0 then   
    self:dropItem(4)
  end
  
  return r
end