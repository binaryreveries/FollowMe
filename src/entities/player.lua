local assets = require("assets")
local base = require('entities.base')
local ctx = require("gamectx.global")
local logger = require("logger.logger")

local player = {}

function player:create(x, y, id)
  local p = {
    -- acceleration in m/s^2
    acceleration=6.5,

    img=assets.img.car,
    width=assets.img.car:getWidth(),
    height=assets.img.car:getHeight(),
    wheelbase=assets.img.car:getHeight() / love.physics.getMeter(),

    joints={},
    body=love.physics.newBody(world, x, y, "dynamic"),
    shape=love.physics.newRectangleShape(0, 0, assets.img.car:getWidth(),
                                         assets.img.car:getHeight()),
    fixture=nil,
    lastX=x,
    lastY=y,
    vx=0,
    vy=0,
    speed=0,
  }
  setmetatable(p, {__index=base})

  if id then
    p:setId(id)
  else
    p:genId()
  end

  -- attach fixture to body and set density to 1 (density increases mass)
  p.fixture = love.physics.newFixture(p.body, p.shape, 1)
  p.body:setMass(1350)

  function p:destroy()
    p.body:destroy()
  end

  function p:update(ground, dt)
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

  function p:draw()
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

  function p:getPosition()
    return self.body:getX(), self.body:getY()
  end

  function p:getTrajectory()
    local vx, vy = self.body:getLinearVelocity()
    return math.atan2(vy, vx)
  end

  function p:beginAccelerate()
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

  function p:endAccelerate()
    self.isaccelerating = false
  end

  function p:endBrake()
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
