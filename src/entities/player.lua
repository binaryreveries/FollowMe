local assets = require("assets")
local netman = require("net.netman")
local base = require('entities.base')

local player = {}

local function createJoint(surface, object, x, y, maxForceFriction, maxTorqueFriction)
  local j = love.physics.newFrictionJoint(surface, object, x, y, true)
  j:setMaxForce(object:getMass() * maxForceFriction)
  j:setMaxTorque(object:getInertia() * maxTorqueFriction)
  return j
end

-- rotate a vector `x, y` in 2D space by `angle`
-- x2=cosβx1−sinβy1
-- y2=sinβx1+cosβy1
local function rotateVector(x, y, angle)
  local s = math.sin(angle)
  local c = math.cos(angle)
  return x*c - y*s, x*s + y*c
end

function player:create(x, y, id)
  local p = {
    acceleration=300,
    turnMultiplier=8,
    wheelForceFriction=50,
    wheelTorqueFriction=1,

    img=assets.img.car,
    width=assets.img.car:getWidth(),
    height=assets.img.car:getHeight(),

    joints={},
    body=love.physics.newBody(world, x, y, "dynamic"),
    shape=love.physics.newRectangleShape(0, 0, assets.img.car:getWidth(),
                                         assets.img.car:getHeight()),
    fixture=nil,
    lastX=x,
    lastY=y,
  }
  setmetatable(p, {__index=base})

  if id then
    p:setId(id)
  else
    p:genId()
  end

  -- attach fixture to body and set density to 1 (density increases mass)
  p.fixture = love.physics.newFixture(p.body, p.shape, 1)

  function p:destroy()
    p.body:destroy()
  end

  function p:update(ground, dt)
    for index, joint in pairs(self.joints) do
      joint:destroy()
    end

    self.joints = {}

    -- setup keyboard event handling
    local inertia = self.body:getInertia()

    local angle = self.body:getAngle()
    local mass = self.body:getMass()
    if self.isaccelerating then
      local fx = mass * -self.acceleration * math.cos(angle)
      local fy = mass * -self.acceleration * math.sin(angle)
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

    local x, y = self.body:getWorldCenter()

    -- wheel coordinates
    local x1, y1 = rotateVector(-self.width/2, -self.height/2, angle) -- front left
    local x2, y2 = rotateVector(self.width/2, -self.height/2, angle) -- front right
    local x3, y3 = rotateVector(-self.width/2, self.height/2, angle) -- rear left
    local x4, y4 = rotateVector(self.width/2, self.height/2, angle) -- rear right

    table.insert(self.joints, createJoint(ground.body, self.body, x + x1, y + y1, self.wheelForceFriction, self.wheelTorqueFriction))
    table.insert(self.joints, createJoint(ground.body, self.body, x + x2, y + y2, self.wheelForceFriction, self.wheelTorqueFriction))
    table.insert(self.joints, createJoint(ground.body, self.body, x + x3, y + y3, self.wheelForceFriction, self.wheelTorqueFriction))
    table.insert(self.joints, createJoint(ground.body, self.body, x + x4, y + y4, self.wheelForceFriction, self.wheelTorqueFriction))

    local vx, vy = self.body:getLinearVelocity()
    self.speed = math.sqrt((vx * vx) + (vy * vy))

    netman:sendCoord(self)
  end

  function p:draw()
    love.graphics.draw(self.img,
    self.body:getX(),
    self.body:getY(),
    self.body:getAngle() - math.pi/2,
    1,
    1,
    self.width/2,
    self.height/2)
  end

  function p:getPosition()
    return self.body:getX(), self.body:getY()
  end

  function p:getTrajectory()
    local vx, vy = self.body:getLinearVelocity()
    return math.atan2(vy, vx)
  end

  function p:beginAccelerating()
    self.isaccelerating = true
  end

  function p:beginBrake()
    self.isbraking = true
  end

  function p:beginReversing()
    self.isreversing = true
  end

  function p:beginTurningLeft()
    self.isturningleft = true
  end

  function p:beginTurningRight()
    self.isturningright = true
  end

  function p:endAccelerating()
    self.isaccelerating = false
  end

  function p:endBraking()
    self.isbraking = false
  end

  function p:endReversing()
    self.isreversing = false
  end

  function p:endTurningLeft()
    self.isturningleft = false
  end

  function p:endTurningRight()
    self.isturningright = false
  end

  return p
end

return player
