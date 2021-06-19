
Tree = Nature:extend()

function Tree:new(id, x, y, scale, health, region, owner, location)
  Tree.super.new(self, id, x, y, scale, health, region, owner, location)
  
  self.class = -3
  self.subclass = 3
  
  self.maxHealth = 10
  
  self.shadow = {50, 87, 30, 10}
  self.center = {53, 87}
  
  self.polygons = {TREE_TRUNK, TREE_TOP}
  self.outlinePolygon = TREE_OUTLINE_POLYGON
  self.fillPolygon = TREE_FILL_POLYGON
  
  self.mainColours = {TREE_TRUNK_COLOUR, TREE_TOP_COLOUR}

  self:colorization()
end

function Tree:updateHealth(dh)
  local r = Tree.super.updateHealth(self, dh)
  
  if dh < 0 then   
    self:dropItem(3)
  end
  
  return r
end