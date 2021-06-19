
Plant = Nature:extend()

function Plant:new(id, x, y, scale, health, region, owner, location)
  Plant.super.new(self, id, x, y, scale, health, region, owner, location)
  
  self.class = -1
  
  self.maxHealth = 10
  
  self.center = {50, 80}
  
  self.branches = {}
  self.leafs = {}
  self.freeBranches = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
  
  for i=1,health do
    self:updateVisual(0)
  end
  
  self:setPolygons()
end

function Plant:setPolygons()
  self.polygons = {self.leafs, self.branches}
  self.boundingBox = self:calculateBoundingBox()
  self.outlinePolygon = self.boundingBox
  self.fillPolygon = self.branches
  
  --self.mainColours = {BUSH_COLOUR, Color(BUSH_COLOUR:getDark())}
  self.mainColours = {Color(225, 50, 20), Color(BUSH_COLOUR:getLight())}  
    
  self:colorization()
end

function Plant:updateVisual(dh)
  if dh < 0 then 
    -- remove a leaf
    self:removeLeaf() 
  else 
    -- if there are branches, or we have no space to put a new branch, add to an existing one
    if #self.branches > 0 and (math.prandom(0,1) > 0.5 or #self.freeBranches < 1) then
      local randBranch = math.random(1, #self.branches)
      self:addToBranch(randBranch)
    else
      local randSpot = self.freeBranches[math.random(1, #self.freeBranches)]
      self:createBranch(randSpot)
    end
  end
  
  -- when dh is 0, the initial polygon is created, and I don't want to call setPolygons 10 times
  if dh ~= 0 then
    self:setPolygons()
  end
end

function Plant:calculateBoundingBox()
  local X1,X2 = self.branches[1][7], self.branches[1][5]
  local Y1,Y2 = self.branches[1][8], self.branches[1][2]
  
  for _,b in ipairs(self.branches) do
    if b[7] < X1 then X1 = b[7] end
    if b[5] > X2 then X2 = b[5] end
    
    if b[8] < Y1 then Y1 = b[8] end
    if b[2] > Y2 then Y2 = b[2] end
  end
  
  self.shadow = {(X1 + X2) * 0.5, Y2, (X2 - X1) * 0.5, 0}
  
  return {X1,Y1, X2,Y1, X2,Y2, X1,Y2}
end

function Plant:addToBranch(branch)
  local b = self.branches[branch]
  
  local X1, X2 = b[7], b[5]
  local Y = b[8]
  
  local offset, offset2 = math.prandom(-10, 10), 0
  local height = math.prandom(10, 15)
  
  if offset <= 0 then
    offset2 = offset
    offset = offset * 0.9
  else
    offset2 = offset * 0.9
  end
  
  -- if they are now in the wrong order, don't keep making them smaller
  if X2 + offset2 < X1 + offset then
    offset2 = offset
  end
  
  self:sortedBranchInsert({X1, Y, X2, Y, X2 + offset2, Y - height, X1 + offset, Y - height})
  self:addLeaf((X1 + X2) * 0.5, offset, Y, height)
end

function Plant:createBranch(location)
  local X = self.center[1] - 25 + location * (50 / 10)
  local Y = self.center[2] + math.prandom(-5, 5)
  
  local width = math.prandom(2, 3)
  local offset = math.prandom(-3, 3)
  local height = math.prandom(10, 15)
  
  self:sortedBranchInsert({X, Y, X + width, Y, X + width + offset, Y - height, X + offset, Y - height}) 
  self:addLeaf((X + X + width) * 0.5, offset, Y, height)
end

function Plant:sortedBranchInsert(b)
  local index = 1
  while index <= #self.branches do
    if self.branches[index][2] > b[2] then
      break
    end
    index = index + 1
  end
  table.insert(self.branches, index, b)
end

function Plant:addLeaf(x, off, y, height)
  local size = math.prandom(1, 2)
  local rand = math.prandom(0.2, 1)
  local randY = -rand * height + y
  local randX = x + off * rand
  
  -- flip leaf to the other side
  if math.prandom(0,1) >= 0.5 then
    size = size * -1
    randX = randX
  else
    randX = randX
  end
  
  -- table.insert(self.leafs, {randX, randY, randX - size, randY - size, randX - size * 6, randY, randX - size, randY + size})
  table.insert(self.leafs, {randX, randY, randX - size, randY - size, randX - size * 2, randY, randX - size, randY + size})
end

function Plant:removeLeaf()
  table.remove(self.leafs)
end

function Plant:updateHealth(dh)
  local r = Plant.super.updateHealth(self, dh)
  self:updateVisual(dh)
  
  if dh < 0 then   
    -- TO DO: _only_ if we're in a region that is being "farmed" right now, drop a seed
    self:dropItem(1)
  end
  
  return r
end

function Plant:clean()
  Plant.super.clean(self)
  
  self.branches = nil
  self.leafs = nil
  self.freeBranches = nil
end