local assets = require("assets")
local base = require('entities.base')

local player = {}
setmetatable(player, {__index=base})

-- create car
function player:load(width, height)
  -- TODO JCD make a constructor
  self:genId()
  self.acceleration = 300

  -- set sprite
  self.img = assets.img.car

  -- set dimensions based on sprite
  self.width = self.img:getWidth()
  self.height = self.img:getHeight()

  self.joints = {}

  self.turnMultiplier = 8

  self.wheelForceFriction = 50
  self.wheelTorqueFriction = 1

  -- place car in center of world and make it dynamic so it can move
  self.body = love.physics.newBody(world, width/2, height/2, "dynamic")
  self.shape = love.physics.newRectangleShape(0, 0, self.width, self.height)

  -- attach fixture to body and set density to 1 (density increases mass)
  self.fixture = love.physics.newFixture(self.body, self.shape, 1)
  self.lastX = self.body:getX()
  self.lastY = self.body:getY()
  self.dx = self.body:getX() - self.lastX
  self.dy = self.body:getY() - self.lastY
  self.trajectory = math.atan2(self.dx, self.dy)
end

function player:draw()
  love.graphics.draw(self.img,
                     self.body:getX(),
                     self.body:getY(),
                     self.body:getAngle() - math.pi/2,
                     1,
                     1,
                     self.width/2,
                     self.height/2)
end

function player:update(ground, dt)
  for index, joint in pairs(self.joints) do
    joint:destroy()
  end

  self.joints = {}

  inertia = self.body:getInertia()

  angle = self.body:getAngle()
  mass = self.body:getMass()
  if self.isaccelerating then
    fx = mass * -self.acceleration * math.cos(angle)
    fy = mass * -self.acceleration * math.sin(angle)
    self.body:applyForce(fx, fy)
  end

  if self.isbraking then
  end

  if self.isturningleft then
    if self.isreversing then
      self.body:applyTorque(self.turnMultiplier * inertia)
    else
      self.body:applyTorque(-self.turnMultiplier * inertia)
    end
  end

  if self.isturningright then
    if self.isreversing then
      self.body:applyTorque(-self.turnMultiplier * inertia)
    else
      self.body:applyTorque(self.turnMultiplier * inertia)
    end
  end

  if self.isreversing then
    fx = mass * self.acceleration * math.cos(angle)
    fy = mass * self.acceleration * math.sin(angle)
    self.body:applyForce(fx, fy)
  end

  x, y = self.body:getWorldCenter()

  -- wheel coordinates
  x1, y1 = rotateVector(-self.width/2, -self.height/2, angle) -- front left
  x2, y2 = rotateVector(self.width/2, -self.height/2, angle) -- front right
  x3, y3 = rotateVector(-self.width/2, self.height/2, angle) -- rear left
  x4, y4 = rotateVector(self.width/2, self.height/2, angle) -- rear right

  table.insert(self.joints, createJoint(ground.body, self.body, x + x1, y + y1, self.wheelForceFriction, self.wheelTorqueFriction))
  table.insert(self.joints, createJoint(ground.body, self.body, x + x2, y + y2, self.wheelForceFriction, self.wheelTorqueFriction))
  table.insert(self.joints, createJoint(ground.body, self.body, x + x3, y + y3, self.wheelForceFriction, self.wheelTorqueFriction))
  table.insert(self.joints, createJoint(ground.body, self.body, x + x4, y + y4, self.wheelForceFriction, self.wheelTorqueFriction))

  vx, vy = self.body:getLinearVelocity()
  self.speed = math.sqrt((vx * vx) + (vy * vy))

  -- get self trajectory for new road object angle
  self.dx = self.body:getX() - self.lastX
  self.dy = self.body:getY() - self.lastY
  self.lastX = self.body:getX()
  self.lastY = self.body:getY()
end

function player:getTrajectory()
  return math.atan2(self.dy, self.dx)
end

-- utils

function createJoint(surface, object, x, y, maxForceFriction, maxTorqueFriction)
  j = love.physics.newFrictionJoint(surface, object, x, y, true)
  j:setMaxForce(object:getMass() * maxForceFriction)
  j:setMaxTorque(object:getInertia() * maxTorqueFriction)
  return j
end

-- rotate a vector `x, y` in 2D space by `angle`
-- x2=cosβx1−sinβy1
-- y2=sinβx1+cosβy1
function rotateVector(x, y, angle)
  s = math.sin(angle)
  c = math.cos(angle)
  return x*c - y*s, x*s + y*c
end

function player:beginAccelerate()
  self.isaccelerating = true
end

function player:beginBrake()
  self.isbraking = true
end

function player:beginReversing()
  self.isreversing = true
end

function player:beginTurningLeft()
  self.isturningleft = true
end

function player:beginTurningRight()
  self.isturningright = true
end

function player:endAccelerate()
  self.isaccelerating = false
end

function player:endBrake()
  self.isbraking = false
end

function player:endReversing()
  self.isreversing = false
end

function player:endTurningLeft()
  self.isturningleft = false
end

function player:endTurningRight()
  self.isturningright = false
end

return player
