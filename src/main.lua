-- FollowMe
-- Move car around using the arrow keys.
-- Compatible with löve 0.8.0 and up

function love.load()
  love.physics.setMeter(16) -- length of a meter in our world is 16px
  world = love.physics.newWorld(0, 0, true) -- create a world with no horizontal or vertical gravity

  width = 650
  height = 650

  -- create car
  player = {}
  -- set sprite
  player.img = love.graphics.newImage("car.png")
  -- set dimensions based on sprite
  player.width = player.img:getWidth()
  player.height = player.img:getHeight()
  -- place car in center of world and make it dynamic so it can move
  player.body = love.physics.newBody(world, width/2, height/2, "dynamic")
  player.shape = love.physics.newRectangleShape(0, 0, player.width, player.height)
  -- attach fixture to body and set density to 1 (density increases mass)
  player.fixture = love.physics.newFixture(player.body, player.shape)
  player.fixture:setRestitution(0.9)
  player.fixture:setFriction(0.5)
  player.acceleration = 30
  player.mass = 1000
  player.body:setMass(player.mass)

  objects = {} -- collection of physical objects
  objects.block1 = {}
  objects.block1.body = love.physics.newBody(world, 200, 300, "dynamic")
  objects.block1.mass = 10
  objects.block1.body:setMass(objects.block1.mass)
  objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
  objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape)

  border = love.graphics.newImage("border.png")
  border:setWrap("repeat")
  borderQuad = love.graphics.newQuad(0, 0, width, border:getHeight(), border:getDimensions())

  objects.borderTop = {}
  objects.borderTop.img = border
  objects.borderTop.width = width
  objects.borderTop.height = objects.borderTop.img:getHeight()
  objects.borderTop.quad = borderQuad
  objects.borderTop.body = love.physics.newBody(world, width/2, objects.borderTop.height/2)
  objects.borderTop.shape = love.physics.newRectangleShape(objects.borderTop.width, objects.borderTop.height)
  objects.borderTop.fixture = love.physics.newFixture(objects.borderTop.body, objects.borderTop.shape)

  objects.borderBottom = {}
  objects.borderBottom.img = border
  objects.borderBottom.width = width
  objects.borderBottom.height = objects.borderBottom.img:getHeight()
  objects.borderBottom.quad = borderQuad
  objects.borderBottom.body = love.physics.newBody(world, width/2, height-objects.borderBottom.height/2)
  objects.borderBottom.shape = love.physics.newRectangleShape(objects.borderBottom.width, objects.borderBottom.height)
  objects.borderBottom.fixture = love.physics.newFixture(objects.borderBottom.body, objects.borderBottom.shape)

  love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
  love.window.setMode(width, height)
end

function love.update(dt)
  world:update(dt) -- put the world in motion!

  f = 0
  angularVelocity = 0
  turnMultiplier = 4

  -- setup keyboard event handling
  if love.keyboard.isDown("w") then
    f = player.body:getMass() * player.acceleration
  end
  if love.keyboard.isDown("s") then
    f = player.body:getMass() * -player.acceleration
  end

  if love.keyboard.isDown("a") then
    angularVelocity = -turnMultiplier
  elseif love.keyboard.isDown("d") then
    angularVelocity = turnMultiplier
  end

  player.body:applyTorque(angularVelocity*player.body:getInertia())

  angle = player.body:getAngle()
  xf = -f * math.cos(angle)
  yf = f * math.sin(angle)
  player.body:applyForce(xf, -yf)

  vx, vy = player.body:getLinearVelocity()
  player.speed = math.sqrt((vx * vx) + (vy * vy))
end

function love.draw()
  love.graphics.setColor(0.28, 0.64, 0.05)
  love.graphics.polygon("fill",
    objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(objects.borderTop.img, objects.borderTop.quad, 0, 0)
  --  objects.borderTop.body:getWorldPoints(objects.borderTop.shape:getPoints()))

  love.graphics.draw(objects.borderBottom.img, objects.borderBottom.quad, 0, objects.borderBottom.body:getY(), 0, 1, -1)
  --  objects.borderBottom.body:getWorldPoints(objects.borderBottom.shape:getPoints()))

  love.graphics.draw(player.img,
                     player.body:getX(),
                     player.body:getY(),
                     player.body:getAngle() - math.pi/2,
                     1,
                     1,
                     player.width/2,
                     player.height/2)

  speedText = string.format("%d m/s", player.speed)

  love.graphics.print(speedText, player.body:getX()+14, player.body:getY()-10)
end
