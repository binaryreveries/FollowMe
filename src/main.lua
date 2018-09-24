-- FollowMe
-- Move car around using the arrow keys.
-- Compatible with löve 0.10.0 and up


turnMultiplier = 8
wheelForceFriction = 50
wheelTorqueFriction = 1
joints = {}

function makeRoad()
  road = {}
  road.img = roadSkin
  road.width = road.img:getWidth()
  road.height = road.img:getHeight()
  road.body= love.physics.newBody(world, road.width, road.height)
  road.shape = love.physics.newRectangleShape(0, 0, road.width, road.height)
  road.body:setX(player.body:getX())
  road.body:setY(player.body:getY())
  road.body:setAngle(player.body:getAngle())
  return road
end


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
  player.acceleration = 300

  objects = {} -- collection of physical objects
  objects.ground = {}
  objects.ground.body = love.physics.newBody(world, width/2, height/2)
  objects.ground.shape = love.physics.newRectangleShape(width, height)

  --objects.block1 = {}
  --objects.block1.body = love.physics.newBody(world, 200, 300, "dynamic")
  --objects.block1.mass = 10
  --objects.block1.body:setMass(objects.block1.mass)
  --objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
  --objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape)

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

  
  roads = {}
  
  roadSkin = love.graphics.newImage("road.png")
  roads[1] = makeRoad()
  
  objects.frontier = {}
  objects.frontier.body = love.physics.newBody(world, roads[1].body:getX() - 30, roads[1].body:getY())
  objects.frontier.shape = love.physics.newRectangleShape(roads[1].width, roads[1].height)
  objects.frontier.fixture = love.physics.newFixture(objects.frontier.body, objects.frontier.shape)
  
  --objects.road = {}
  --objects.road.img = road
  --objects.road.width = objects.road.img:getWidth()
  --objects.road.height = objects.road.img:getHeight()
  --objects.road.body= love.physics.newBody(world, objects.road.width, objects.road.height)
  --objects.road.shape = love.physics.newRectangleShape(0, 0, objects.road.width, objects.road.height)
  --objects.road.body:setX(player.body:getX())
  --objects.road.body:setY(player.body:getY())
  --objects.road.body:setAngle(player.body:getAngle())
  
  
  
  love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
  love.window.setMode(width, height)
end

-- rotate a vector `x, y` in 2D space by `angle`
-- x2=cosβx1−sinβy1
-- y2=sinβx1+cosβy1
function rotateVector(x, y, angle)
  s = math.sin(angle)
  c = math.cos(angle)
  return x*c - y*s, x*s + y*c
end

function createJoint(surface, object, x, y, maxForceFriction, maxTorqueFriction)
  j = love.physics.newFrictionJoint(surface, object, x, y, true)
  j:setMaxForce(object:getMass() * maxForceFriction)
  j:setMaxTorque(object:getInertia() * maxTorqueFriction)
  return j
end

function love.update(dt)
  world:update(dt) -- put the world in motion!

  for index, joint in pairs(joints) do
    joint:destroy()
  end

  joints = {}

  -- setup keyboard event handling
  inertia = player.body:getInertia()
  if love.keyboard.isDown("a") then
    player.body:applyTorque(-turnMultiplier * inertia)
  elseif love.keyboard.isDown("d") then
    player.body:applyTorque(turnMultiplier * inertia)
  end

  angle = player.body:getAngle()
  mass = player.body:getMass()
  if love.keyboard.isDown("w") then
    fx = mass * -player.acceleration * math.cos(angle)
    fy = mass * -player.acceleration * math.sin(angle)
    player.body:applyForce(fx, fy)
  elseif love.keyboard.isDown("s") then
    fx = mass * player.acceleration * math.cos(angle)
    fy = mass * player.acceleration * math.sin(angle)
    player.body:applyForce(fx, fy)
  end

  x, y = player.body:getWorldCenter()

  -- wheel coordinates
  x1, y1 = rotateVector(-player.width/2, -player.height/2, angle) -- front left
  x2, y2 = rotateVector(player.width/2, -player.height/2, angle) -- front right
  x3, y3 = rotateVector(-player.width/2, player.height/2, angle) -- rear left
  x4, y4 = rotateVector(player.width/2, player.height/2, angle) -- rear right

  table.insert(joints, createJoint(objects.ground.body, player.body, x + x1, y + y1, wheelForceFriction, wheelTorqueFriction))
  table.insert(joints, createJoint(objects.ground.body, player.body, x + x2, y + y2, wheelForceFriction, wheelTorqueFriction))
  table.insert(joints, createJoint(objects.ground.body, player.body, x + x3, y + y3, wheelForceFriction, wheelTorqueFriction))
  table.insert(joints, createJoint(objects.ground.body, player.body, x + x4, y + y4, wheelForceFriction, wheelTorqueFriction))

  vx, vy = player.body:getLinearVelocity()
  player.speed = math.sqrt((vx * vx) + (vy * vy))

  if (x < 0) then
    player.body:setPosition(width, y)
  elseif (x > width) then
    player.body:setPosition(0, y)
  end
  
  -- paving new road
  
  distance = love.physics.getDistance(player.fixture, objects.frontier.fixture)
  
  if (distance < 2) then
    objects.frontier.body:setX(player.body:getX() - 30 + .1 * player.body:getLinearVelocity())
    objects.frontier.body:setY(player.body:getY())
    table.insert(roads, makeRoad())
  end
end

function love.draw()
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.polygon("fill",
    objects.ground.body:getWorldPoints(objects.ground.shape:getPoints()))

  love.graphics.setColor(0.28, 0.64, 0.05)
  --love.graphics.polygon("fill",
  --  objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(objects.borderTop.img, objects.borderTop.quad, 0, 0)

  love.graphics.draw(objects.borderBottom.img, objects.borderBottom.quad, 0, objects.borderBottom.body:getY(), 0, 1, -1)

  for index, road in pairs(roads) do
    love.graphics.draw(road.img,
                       road.body:getX(),
                       road.body:getY(), -- need to shift so that car is in center, using width, height and Angle
                       road.body:getAngle())
  end                   
  love.graphics.polygon("fill",
    objects.frontier.body:getWorldPoints(objects.frontier.shape:getPoints())
  )
  
  distText = string.format(distance)
  love.graphics.print(distText, objects.frontier.body:getX() + 20, objects.frontier.body:getY() + 20)
    
  
  love.graphics.setColor(0.28, 0.64, 0.05)
  love.graphics.polygon("line",
    player.body:getWorldPoints(player.shape:getPoints()))
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

function love.filedropped(file)
  player.img = love.graphics.newImage(file)
end
