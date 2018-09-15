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
  player.fixture = love.physics.newFixture(player.body, player.shape, 1)
  player.fixture:setRestitution(0.9)
  player.fixture:setFriction(0.5)
  player.acceleration = 30

  objects = {} -- collection of physical objects
  objects.block1 = {}
  objects.block1.body = love.physics.newBody(world, 200, 300, "dynamic")
  objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
  objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape, 5)

  love.window.setMode(width, height)
end

function love.update(dt)
  world:update(dt) -- put the world in motion!

  angle = player.body:getAngle()
  f = 0
  turnMultiplier = math.pi / 64

  -- setup keyboard event handling
  if love.keyboard.isDown("w") then
    f = player.body:getMass() * player.acceleration
  end
  if love.keyboard.isDown("s") then
    f = player.body:getMass() * -player.acceleration
  end

  if love.keyboard.isDown("a") then
    angle = angle - turnMultiplier
  elseif love.keyboard.isDown("d") then
    angle = angle + turnMultiplier
  end
  player.body:setAngle(angle)
  xf = -f * math.cos(angle)
  yf = f * math.sin(angle)
  player.body:applyForce(xf, -yf)
end

function love.draw()
  love.graphics.setColor(0.28, 0.64, 0.05)
  love.graphics.polygon("fill",
    objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(player.img,
                     player.body:getX(),
                     player.body:getY(),
                     player.body:getAngle() - math.pi/2,
                     1,
                     1,
                     player.width/2,
                     player.height/2)
end
