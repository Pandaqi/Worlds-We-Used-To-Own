
Player = Object:extend()

function Player:new(num, class, friendList)
  self.num = num
  self.class = class
  self.friendList = friendList

  self.regions = {}  
  self.units = {}
end

function Player:setFriend(player, value)
  self.friendList[player] = value
end

-- Adds a region into this player's possession
function Player:addRegion(i)
  table.insert(self.regions, i)
end

-- Throws away old regions and gives it a completely new set
function Player:setRegions(reg)
  self.regions = reg
end

-- Receives a message from the world saying something happened, which we need to react to
function Player:receiveSignal(e)
  print("Player " .. self.num .. " received signal " .. e)
end