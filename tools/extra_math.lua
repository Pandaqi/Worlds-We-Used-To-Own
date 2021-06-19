-- Returns 1 if the lines intersect, otherwise 0. In addition, if the lines 
-- intersect the intersection point may be stored in the floats i_x and i_y.
function math.performIntersect(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)
    local s1_x = p1_x - p0_x
    local s1_y = p1_y - p0_y
    local s2_x = p3_x - p2_x
    local s2_y = p3_y - p2_y
    
    local D = (-s2_x * s1_y + s1_x * s2_y)
    if D == 0 then
      print("COLLINEARITY of lines")
      return -1, -1
    end
    
    local s3_x = (p0_x - p2_x)
    local s3_y = (p0_y - p2_y)

    local s = (-s1_y * s3_x + s1_x * s3_y) / D
    local t = ( s2_x * s3_y - s2_y * s3_x) / D
    
    local X,Y = -1, -1

    -- there is an intersection!
    if s >= 0 and s <= 1 and t >= 0 and t <= 1 then
      X = p0_x + (t * s1_x)
      Y = p0_y + (t * s1_y)
    else
      local dist1 = s3_x * s3_x + s3_y * s3_y
      local dist2 = (p0_x - p3_x)*(p0_x - p3_x) + (p0_y - p3_y)*(p0_y - p3_y)
      
      if dist1 < dist2 then
        X,Y = p2_x, p2_y
      else
        X,Y = p3_x, p3_y
      end
      
      -- if there is no intersection, return closest point
      -- I DON'T KNOW HOW, so let's return the center for now
      -- X,Y = (p2_x+p3_x)*0.5, (p2_y+p3_y)*0.5
    end

    return X,Y
end

--[[ function math.performIntersect(x1, y1, x2, y2, X1, Y1, X2, Y2)
  local m = (y2 - y1) / (x2 - x1)
  local n = (Y2 - Y1) / (X2 - X1)
  
  local x = (x1 * m - X1 * n + Y1 - y1) / (m - n)
  local y = m * (x - x1) + y1
  
  return x,y
end --]]

-- Mixes the DNA of two parents, with a slight chance for mutations
-- Normal values: 0 and 1
-- Extreme values: -1 and 2
function math.mixDNA(p1, p2) 
  local parents = {p1, p2}
  if #p1 ~= #p2 then
    print("Error: DNA not of equal length")
    return
  end
  
  local DNA = {}
  
  for i=1,#p1 do
    DNA[i] = {}
    for j=1,2 do
      local newValue = parents[j][i][math.random(1,2)]
      
      -- if mutation, 50% chance of going towards extreme value, 50% chance of going towards handicapped value
      if math.prandom(0,10) < 0.1 then
        if math.prandom(0,1) < 0.5 then
          newValue = newValue - 1
        else
          newValue = newValue + 1
        end
      end
      
      DNA[i][j] = newValue
    end
  end
  
  return DNA
end

function math.getMax(t)
  if #t == 0 then return nil, nil end
  local key, value = 1, t[1]
  for i = 2, #t do
      if t[i] > value then
          key, value = i, t[i]
      end
  end
  return { key = key, value = value }
end

function math.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[math.copy(k, s)] = math.copy(v, s) end
  return res
end

function math.mod(n, limit)
  if n > limit then n = n - limit end
  if n < 1 then n = n + limit end
  return n
end

function math.getMin(t)
  if #t == 0 then return nil, nil end
  local key, value = 1, t[1]
  for i = 2, #t do
      if t[i] < value then
          key, value = i, t[i]
      end
  end
  return { key = key, value = value }
end

function math.inTable(table, item)
    for key, value in pairs(table) do
      if value == item then return key end
    end
    return false
end

function math.round(n) return math.floor(n + 0.5) end

function math.clamp(low, n, high) return math.min(math.max(low, n), high) end

function math.prandom(min, max) return math.random() * (max - min) + min end

function math.drandom(min, max) return love.math.random() * (max - min) + min end

function math.rsign() return love.math.random(2) == 2 and 1 or -1 end

function math.randexp(mean)
  return -math.log(math.drandom(0,1)) * mean
end

function print_r(arr, indentLevel)
  local str = ""
  local indentStr = "#"

  if(indentLevel == nil) then
      print(print_r(arr, 0))
      return
  end

  for i = 0, indentLevel do
      indentStr = indentStr.."\t"
  end

  for index,value in pairs(arr) do
      if type(value) == "table" then
          str = str..indentStr..index..": \n"..print_r(value, (indentLevel + 1))
      else 
          str = str..indentStr..index..": ".. tostring(value) .."\n"
      end
  end
  return str
end
