local util = require("util.util")

local base = {}

function base:genId()
  self.id = util:randHex()
end

function base:setId(id)
  self.id = id
end

function base:getId()
  return self.id
end

function base:setCoord(coord)
  self.body:setX(coord.x)
  self.body:setY(coord.y)
  self.body:setLinearVelocity(coord.vX, coord.vY)
  self.body:setAngle(coord.angle)
  self.body:setAngularVelocity(coord.vAngle)
end

function base:getCoord()
  local coord = {}
  coord.x = self.body:getX()
  coord.y = self.body:getY()
  coord.vX, coord.vY = self.body:getLinearVelocity()
  coord.angle = self.body:getAngle()
  coord.vAngle = self.body:getAngularVelocity()
  return coord
end

return base
