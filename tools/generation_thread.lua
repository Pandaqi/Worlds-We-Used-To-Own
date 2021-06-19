
Object = require "tools/classic"

c = love.thread.getChannel("mapGenerator")
-- blabla = c:pop() to get user defined settings
math.randomseed(os.time())

-- create random map
VORONOI = require "tools/voronoi"
final_voronoi = nil

-- some data about the map (size, amount players, etc.)
local map_data = { x = 0, y = 0, width = 2000, height = 1000 }
local amount_polygons = 220
local amount_players = 6
  
-- keep trying until we find one that looks good
while final_voronoi == nil do
  final_voronoi = VORONOI:new(amount_polygons, 3, 0, 0, map_data.width, map_data.height)
  c:push("update counter")
end


-- reimport some things here, because we're on a different thread
require "tools/color"
require "love.math"
require "tools/extra_math"
require "global_dictionaries"

-- initiate the event set, start time
require "events"
EVENTS = Events(0, -1, {}, 0)
EVENTS:addEvent({ONE_YEAR * 0.25, "seasonchange"})

-- create regions (by polygon, centroid, and owner)
require "region"
require "nature"
require "nature/tree"
require "nature/stone"
require "nature/bush"
require "nature/plant"
require "nature/item"
REGIONS = {}
ID = 0

for index,polygon in pairs(final_voronoi.polygons) do
  table.insert(REGIONS, Region(index, polygon.points, final_voronoi.centroids[index]))
end

c:push("update counter")

-- populate the regions' connection list
for pointindex,relationgroups in pairs(final_voronoi.polygonmap) do
  for badindex,subpindex in pairs(relationgroups) do
    REGIONS[pointindex]:addNeighbour(subpindex)
  end
end

-- set base terrain for each region
-- first, create spots with water
local water_spots = 4
for i=1,water_spots do
  REGIONS[math.random(#REGIONS)]:setTerrain(1)
end

-- then, create mountains
local mountain_spots = 4
for i=1,mountain_spots do
  REGIONS[math.random(#REGIONS)]:setTerrain(9)
end

-- then, develop outward (10 iterations is a random number really, but should be enough)
local map_iterations = 10
for i=1,map_iterations do
  for j,r in ipairs(REGIONS) do
    r:adjustTerrain()
  end
end

c:push("update counter")

-- add the environment
for _,r in ipairs(REGIONS) do
  
  r:calculateBoundingBox()
  r:calculateInnerPolygon()
  r:calculateFreeLocations()
  r:calculateNeighbourLines()
  r:calculateGroundLines()
  
  r:setWeatherStatus(math.random(0,1))
  
  -- WATER
  if r.terrain <= 3 then
    
    for i,n in pairs(r.conn) do
      
      -- figure out which of them is not water
      if REGIONS[n]:getTerrain() > 3 then
        local c = r.connLines[n]
        r:addShoreLine(c[1], c[2], c[3], c[4], r.centroid.x, r.centroid.y) 
        r:addShoreLine(c[1], c[2], c[3], c[4], r.centroid.x, r.centroid.y) 
      end
      
    end
    
  -- MOUNTAIN
  elseif r.terrain >= 7 then
    
    for i,n in pairs(r.conn) do
      
      -- figure out which of them is lower in elevation level than we are
      if REGIONS[n]:getTerrain() < r.terrain then
        local c = r.connLines[n]
        REGIONS[n]:addMountainLine(c[1], c[2], c[3], c[4], r.centroid.x, r.centroid.y)
      end
      
    end
    
  -- GRASS
  else
    local rand = math.random(1,2)
    for i=1,rand do
      r:addNature('tree')
    end
    
    rand = math.random(0,1)
    for i=1,rand do
      r:addNature('stone')
    end
    
    rand = math.random(0,1)
    for i=1,rand do
      r:addNature('bush')
    end
    
    rand = math.random(0, 1)
    for i=1,rand do
      r:addNature('plant')
    end
  end
  
  local p = {}
  for i=1,amount_players do
    p[i] = 0
  end
  
  r:setPresence(p)
end

-- create rivers
local river_iterations = 10
for i=1,river_iterations do
  for j,r in ipairs(REGIONS) do
    r:adjustRiver()
  end
end

for j,r in ipairs(REGIONS) do
  r:cleanRiver()
end

c:push("update counter")

-- generate players and their starting animals
require "player"
require "animal"
require "animals/bunny"
require "buildings/home"
local players = {}
local playerClasses = {1, 1, 1, 1, 1, 1}
local animals = {}
local num_animals = 3

for i=1,amount_players do
  table.insert(players, Player(i, playerClasses[i], {}))
  
  -- find out who's friendly and who's not
  for j=1,amount_players do
    if i == j then
      players[i]:setFriend(j, 1)
    else
      players[i]:setFriend(j, 0)
    end
  end
end

local startingCam = {}

local parentDNA = {{0,1},{0,1},{0,1},{0,1},{0,1},{0,1},{0,1},{0,1},{0,1},{0,1}}

-- give each player a starting region
for i=1,#players do
  -- of course, only assign regions that aren't yet claimed
  local rand_index = math.random(#REGIONS)
  while REGIONS[rand_index]:getOwner() ~= 0 or REGIONS[rand_index]:getTerrain() <= 3 or REGIONS[rand_index]:getTerrain() >= 7 do
    rand_index = math.random(#REGIONS)
  end
  local rand_region = REGIONS[rand_index]
  rand_region:setOwner(i)
  
  -- add the region to the player's regions
  players[i]:addRegion(rand_index)
  
  -- update the fog (and center the camera) for the actual human player
  if i == 1 then 
    rand_region:updateFog(0, rand_index) 
    startingCam = {rand_region:getCentroid().x, rand_region:getCentroid().y, 1}
  end
  
  -- add the animal home to the starting region
  rand_region:addBuilding("home", i)
  
  rand_region:updatePresence(i, num_animals)
  
  -- add the animals to their regions
  local genders = {true, false, true}
  local age = {4, 4, 1}
  for j=1,num_animals do
    local rp = rand_region:randomPoint("animal")
    if rp == nil then
      rp = rand_region.centroid
    end
    local scaleFromAge = age[j] / ANIMAL_PROPS[1][1] * ANIMAL_PROPS[1][2]
    local DNA = math.mixDNA(parentDNA, parentDNA)
    local b = Bunny(ID, i, genders[j], age[j], rp.x, rp.y, scaleFromAge, 10, 0, rand_index, 1, false, 10, DNA)
    b:startEvents()
    rand_region:addAnimal(b)
  end
end

-- remove properties we won't need or use anyway
for i,r in pairs(REGIONS) do
  r:clean()
  for i,a in pairs(r.nature) do
    a:clean()
  end
end

EVENTS:clean()

-- THIS SAVES THE MAP (and other data) TO A SAVE FILE
local serialize = require 'tools/ser'
love.filesystem.write('savegame', serialize({REGIONS, players, map_data, startingCam, EVENTS}))

c:push("all done")