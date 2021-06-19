
Bush = Nature:extend()

function Bush:new(id, x, y, scale, health, region, owner, location)
  Bush.super.new(self, id, x, y, scale, health, region, owner, location)
  
  self.class = -5
  
  self.maxHealth = 10
  self.subclass = 2
  
  self.shadow = {50, 74, 45, 13}
  self.center = {50, 82}
  
  self.polygons = {BUSH_POLYGON}
  self.outlinePolygon = BUSH_OUTLINE_POLYGON
  self.fillPolygon = BUSH_FILL_POLYGON
  
  self.mainColours = {BUSH_COLOUR}
  
  self:colorization()
end

function Bush:updateHealth(dh)
  local r = Bush.super.updateHealth(self, dh)
  
  if dh < 0 then   
    if math.prandom(0,1) >= 0.5 then
      self:dropItem(3)
    else
      self:dropItem(2)
    end
  end
  
  return r
end
