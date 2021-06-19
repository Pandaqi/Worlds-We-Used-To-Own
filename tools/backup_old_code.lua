

function Region:getNeighbourString()
  local s = ""
  for i,n in pairs(self.conn) do
    if n then
      s = s .. " | " .. i
    end
  end
  return s
end

function Region:getNeighbours()
  local s = {}
  for i,n in pairs(self.conn) do
    if n then
      table.insert(s, n)
    end
  end
  return s
end

-----


  local new_terrain = 0
  new_terrain = first + 1

  -- with a very small probability, we stay the same as our best neighbour
  if math.prandom(0,1) < 0.025 then
    new_terrain = first
  else
    -- otherwise, if we're quite high, there's some chance that we actually go down a level
    if math.prandom(0,1) < 0.35 and last >= 5 and new_terrain >= 5 then
      new_terrain = new_terrain - 1
    end
  end



------

    -- draw roads (experimental)
    -- roads are only drawn on land (duh), and only between regions owned by the same player
    for i,c in pairs(self.conn) do
      local r = REGIONS[i]
      if r:getIndex() < self.index and self.owner > 0 and self.terrain > 3 and r:getTerrain() > 3 and self.owner == r:getOwner() then
        love.graphics.setColor(ROAD_COLOUR:get())
        love.graphics.setLineWidth(3)
        love.graphics.line(self.centroid.x, self.centroid.y, r.centroid.x, r.centroid.y)
      end
    end
    
  
    love.graphics.setColorMask(true, true, true, true)
  
  local shader = love.graphics.newShader[[
    extern number centerX;
    extern number centerY;
    extern number radius;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords);
      number factor = (screen_coords.x - centerX)*(screen_coords.x - centerX) + (screen_coords.y - centerY)*(screen_coords.y - centerY);
      //number factor = (texture_coords.x - 0.5)*(texture_coords.x - 0.5) + (texture_coords.y - 0.5) * (texture_coords.y - 0.5);
      color.a = factor / (radius * radius);
      color.r = 1.0;
      color.g = color.r;
      color.b = color.g;
      return color;
    }
  ]]
  
  love.graphics.setShader(shader)
  
  love.graphics.setColor(0, 0, 0, 255)
  
      
    shader:send("centerX", tX)
    shader:send("centerY", tY)
    shader:send("radius", rad)
    
      love.graphics.setShader()