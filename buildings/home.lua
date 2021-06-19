
Home = Nature:extend()

function Home:new(id, x, y, scale, terrain, health, region, owner, location)
  Home.super.new(self, id, x, y, scale, health, region, owner, location)
  
  self.class = 0
  
  self.maxHealth = 10
  
  self.shadow = {50, 61, 45, 10}
  --self.shadow = {50, 61, 0,0}
  self.center = {50, 61}
  
  self.polygons = HOME_POLYGONS[1]
  self.outlinePolygon = HOME_OUTLINES[1]
  self.fillPolygon = HOME_FILL_OUTLINES[1]
  
  self.mainColours = {Color(30, 30, 30), Color(198, 165, 137), Color(75, 75, 75, 75), Color(TERRAIN_COLOUR_MAP[terrain]:getLight())}
  
  self:colorization()
end

function Home:getName()
  return "UNNABUNA"
end

function Home:die()
  REGIONS[self.region]:addToRemovalQueue(self)
end

function Home:setResources(r)
  self.resources = r
  self.resourcesNeeded = {0, 0, 5, 0} -- seeds, leafs, wood, stone
end

function Home:addResource(subc)
  self.resources[subc] = self.resources[subc] + 1
end

function Home:checkResources(animalItem)
  local resourceDeficit = {}
  local tempSum, tempSum2 = 0,0
  local targets = {}
  
  -- already take into account the animal's item that's going towards this building
  if animalItem ~= nil then
    tempSum = 1
  end
  
  -- check how much we have, what we need, and how much we lack
  for i=1,4 do
    resourceDeficit[i] = self.resourcesNeeded[i] - self.resources[i]
    
    if resourceDeficit[i] > 0 then
      table.insert(targets, i)
    end
    
    tempSum = tempSum + self.resources[i]
    tempSum2 = tempSum2 + self.resourcesNeeded[i]
  end
  
  -- return whether we have enough resources, and if not, also what our target resources are
  return tempSum >= math.floor(((tempSum2 + 1) / self.maxHealth) * self.health), targets
end