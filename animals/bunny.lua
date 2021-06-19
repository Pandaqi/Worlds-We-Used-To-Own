
Bunny = Animal:extend()

-- Gender is a boolean: true is FEMALE, false is MALE

function Bunny:new(id, owner, gender, age, x, y, scale, health, illness, region, modifier, inside, nutrition, DNA)
  self.class = 1
  
  Bunny.super.new(self, id, owner, gender, age, x, y, scale, health, illness, region, modifier, inside, nutrition, DNA)
  
  self.center = {50, 88}
  self.shadow = {60, 90, 30, 10}
  self.itemPosition = {16, 46}
  
  -- the index of special facial features
  self.ears = {14, 15, 16}
  self.eyes = {4}
  
  -- RETRIEVE POLYGONS FROM LIBRARY
  self.headPoly = ANIMAL_POLYGONS[1][1]
  self.bodyPoly = ANIMAL_POLYGONS[1][2]
  self.frontLegPoly = ANIMAL_POLYGONS[1][3]
  self.backLegPoly = ANIMAL_POLYGONS[1][4]
  self.outlinePoly = ANIMAL_POLYGONS[1][5]
  self.outlinePolyTriangles = ANIMAL_POLYGONS[1][6]
  
  -- the pivot around which to rotate body parts
  self.backLegPivot = {x = 75, y = 70}
  self.frontLegPivot = {x = 43, y = 76}
  self.headPivot = {x = 40, y = 40}
  
  self.colors = {{}, {}, {}, {}}
  
  local myEarColour = Color(230, 205, 183)
  local myFurColour = ANIMAL_COLOUR_MAP[1]
  local myEyeColour = Color(110, 110, 110)
  
  if self.DNA[9][1] == 0 and self.DNA[9][2] == 0 then
    myFurColour = Color(ANIMAL_COLOUR_MAP[1]:getDark())
  end
  
  if self.DNA[10][1] == 0 and self.DNA[10][1] == 0 then
    myEyeColour = Color(240, 120, 120)
  end
  
  for i=1,#self.headPoly do
    if math.inTable(self.ears, i) then
      table.insert(self.colors[1], myEarColour:getRandom())
    elseif math.inTable(self.eyes, i) then
      table.insert(self.colors[1], myEyeColour)
    else
      table.insert(self.colors[1], myFurColour:getRandom())
    end
  end
  
  for i=1,#self.bodyPoly do
    table.insert(self.colors[2], myFurColour:getRandom())
  end
  
  for i=1,#self.frontLegPoly do
    table.insert(self.colors[3], myFurColour:getRandom())
  end
  
  for i=1,#self.backLegPoly do
    table.insert(self.colors[4], myFurColour:getRandom())
  end
end