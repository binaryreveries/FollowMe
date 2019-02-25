local assets = require("assets")
local base = require('entities.base')
local ctx = require("gamectx.global")
local logger = require("logger.logger")

local player = {}
setmetatable(player, {__index=base})

-- create car
function player:load(width, height)
  -- TODO JCD make a constructor
  self:genId()
  -- acceleration in m/s^2
  self.acceleration = 6.5

  -- set sprite
  self.img = assets.img.car

  -- set dimensions based on sprite
  self.width = self.img:getWidth()
  self.height = self.img:getHeight()
  self.wheelbase = self.height / love.physics.getMeter()

  -- place car in center of world and make it dynamic so it can move
  self.body = love.physics.newBody(world, width/2, height/2, "dynamic")
  self.shape = love.physics.newRectangleShape(0, 0, self.width, self.height)

  -- attach fixture to body and set density to 1 (density increases mass)
  self.fixture = love.physics.newFixture(self.body, self.shape, 1)
  -- set mass to 1350 kg, avg mass of compact
  self.body:setMass(1350)
  self.lastX = self.body:getX()
  self.lastY = self.body:getY()
  self.dx = self.body:getX() - self.lastX
  self.dy = self.body:getY() - self.lastY
  self.vx, self.vy = self.body:getLinearVelocity()
  self.speed = math.sqrt(self.vx^2 + self.vy^2)
  self.trajectory = math.atan2(self.dx, self.dy)
end

function player:draw()
  love.graphics.draw(self.img,
                     self.body:getX(),
                     self.body:getY(),
                     self.body:getAngle(),
                     1,
                     1,
                     self.width/2,
                     self.height/2)
  if ctx:get('debugEnabled') then
      -- save current color settings
      r, g, b, a = love.graphics.getColor()

      love.graphics.setColor(1.00, 1.00, 1.00)
      love.graphics.line(self.body:getX(), self.body:getY(),
        self.body:getX() + self.force.longitude.x,
        self.body:getY() + self.force.longitude.y)

      love.graphics.setColor(1.00, 0.00, 0.00)
      love.graphics.line(self.body:getX(), self.body:getY(),
        self.body:getX() + self.force.traction.x,
        self.body:getY() + self.force.traction.y)

      love.graphics.setColor(0.00, 1.00, 0.00)
      love.graphics.line(self.body:getX(), self.body:getY(),
        self.body:getX() + self.force.resist.rolling.x,
        self.body:getY() + self.force.resist.rolling.y)

      love.graphics.setColor(0.00, 0.00, 1.00)
      love.graphics.line(self.body:getX(), self.body:getY(),
        self.body:getX() + self.force.resist.drag.x,
        self.body:getY() + self.force.resist.drag.y)

      -- reset colors
      love.graphics.setColor(r, g, b, a)
  end
end

function player:update(ground, dt)
  self.dx = self.body:getX() - self.lastX
  self.dy = self.body:getY() - self.lastY

  self.lastX = self.body:getX()
  self.lastY = self.body:getY()

  local angle = self.body:getAngle()
  local turnangle = 0
  if self.isturningleft then
      turnangle = -math.pi/2
  end
  if self.isturningright then
      turnangle = math.pi/2
  end

  -- density of air kg/m^3 (0.0801 lb-mass/ft^3)
  local airDensity = 1.29
  -- frontal area of the car m^2
  local frontalArea = 2.2

  local unitx = math.cos(angle)
  local unity = math.sin(angle)

  local ax, ay = 0, 0
  if self.isaccelerating then
      ax = self.acceleration * unitx
      ay = self.acceleration * unity
  end
  if self.isreversing then
      ax = self.acceleration * -unitx
      ay = self.acceleration * -unity
  end

  self.vx, self.vy = self.body:getLinearVelocity()
  self.speed = math.sqrt(self.vx^2 + self.vy^2)
  logger:debug("acceleration: (%.0f, %.0f); velocity: (%.0f, %.0f)",
    ax, ay, self.vx, self.vy)

  local turnradius = self.wheelbase / math.sin(turnangle)
  self.angularVelocity = self.speed / turnradius
  logger:debug("speed: %.0f; angular velocity: %.0f",
    self.speed, self.angularVelocity)
  self.body:applyTorque(self.angularVelocity)

  self.force = {}
  self.force.resist = {}

  self.force.resist.drag = {}
  self.force.resist.drag.base = 0.5 *
                                ground.friction.coefficient *
                                frontalArea *
                                airDensity *
                                self.speed
  self.force.resist.drag.x = self.force.resist.drag.base * -self.vx
  self.force.resist.drag.y = self.force.resist.drag.base * -self.vy

  self.force.resist.rolling = {}
  self.force.resist.rolling.base = 30 * self.force.resist.drag.base
  self.force.resist.rolling.x = self.force.resist.rolling.base * -self.vx
  self.force.resist.rolling.y = self.force.resist.rolling.base * -self.vy

  -- F_traction = unit vector of heading * engine force
  self.force.traction = {}
  self.force.traction.x = self.body:getMass() * ax
  self.force.traction.y = self.body:getMass() * ay

  self.force.longitude = {}
  self.force.longitude.x = self.force.traction.x +
                           self.force.resist.drag.x +
                           self.force.resist.rolling.x

  self.force.longitude.y = self.force.traction.y +
                           self.force.resist.drag.y +
                           self.force.resist.rolling.y

  logger:debug("engine: (%.0f, %.0f); rr: (%.0f, %.0f); drag: (%.0f, %.0f)",
    self.force.traction.x, self.force.traction.y,
    self.force.resist.rolling.x, self.force.resist.rolling.y,
    self.force.resist.drag.x, self.force.resist.drag.y)

  logger:debug("longitude: (%.0f, %.0f)", self.force.longitude.x,
    self.force.longitude.y)
  self.body:applyForce(self.force.longitude.x, self.force.longitude.y)
end

function player:getTrajectory()
  return math.atan2(self.dy, self.dx)
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
