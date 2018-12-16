local assets = require "assets"
local player = { }

-- create car
function player:load(width, height)
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
end

function player:draw()
  angle = self.body:getAngle() % (2*math.pi)
  trajectory = self:getTrajectory()
  directionalDelta = trajectory - angle
  love.graphics.print("trajectory: "..trajectory.."", 20, 20)
  love.graphics.print("angle: "..angle.."", 20, 40)
  love.graphics.print("delta: "..directionalDelta.."", 20, 60)
  love.graphics.draw(self.img,
                     self.body:getX(),
                     self.body:getY(),
                     self.body:getAngle(),
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

  mass = self.body:getMass()
  inertia = self.body:getInertia()
  angle = self.body:getAngle() % (2*math.pi)
  trajectory = self:getTrajectory()

  directionalDelta = trajectory - angle

  if directionalDelta < (-math.pi/2) and directionalDelta > (-3*math.pi/2)then
    direction = -1
  else
    direction = 1
  end

  -- setup keyboard event handling
  if love.keyboard.isDown("a") then
    self.body:applyTorque(direction * -self.turnMultiplier * inertia)
  elseif love.keyboard.isDown("d") then
    self.body:applyTorque(direction * self.turnMultiplier * inertia)
  end

  fx = mass * self.acceleration * math.cos(angle)
  fy = mass * self.acceleration * math.sin(angle)

  if love.keyboard.isDown("w") then
    self.body:applyForce(fx, fy)
  elseif love.keyboard.isDown("s") then
    self.body:applyForce(-fx, -fy)
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

return player
