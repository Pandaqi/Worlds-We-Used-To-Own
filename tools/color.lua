
Color = Object:extend()

function Color:new(r, g, b, a)
  self.r = r or 0
  self.g = g or 0
  self.b = b or 0
  self.a = a or 255
end

function Color:get()
  return self.r, self.g, self.b, self.a
end

function Color:getDark()
  return self.r * 0.8, self.g * 0.8, self.b * 0.8, self.a
end

function Color:getDesaturatedDark()
  return self.r * 0.5, self.g * 0.7, self.b * 0.6
end

function Color:getLight()
  return self.r * 1.2, self.g * 1.2, self.b * 1.2, self.a
end

function Color:getVeryLight()
  return self.r * 1.6, self.g * 1.6, self.b * 1.6, self.a
end

function Color:getAlpha(a)
  return self.r, self.g, self.b, a
end

function Color:getRandom()
  local rand = math.drandom(-50, 50)
  return Color(self.r + rand*0.299, self.g + rand*0.587, self.b + rand*0.114)
end