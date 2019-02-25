-- FollowMe
-- Move car around using the arrow keys.
local argparse = require("argparse.argparse")
local assets = require("assets")
local camera = require("entities.camera")
local ctx = require('gamectx.global')
local ground = require("entities.ground")
local logger = require("logger.logger")
local netman = require("net.netman")
local player = require("entities.player")
local road = require("entities.road")
local util = require("util.util")

world = nil
local block1 = nil
local border = nil
local height = 650
local width = 650

function love.load(args)
  ctx:load()
  argparse:parse(args)
  logger:debug("debug mode enabled")
  for k, v in pairs(ctx:getArgs()) do
    logger:debug("\t%s -> %s", k, v)
  end

  love.physics.setMeter(16) -- length of a meter in our world is 16px
  world = love.physics.newWorld(0, 0, true) -- create a world with no horizontal or vertical gravity

  assets:load()
  camera:load()
  ground:load(width, height)
  player:load(width, height)

  objects = {}
  objects.block1 = {}
  objects.block1.body = love.physics.newBody(world, 200, 500, "dynamic")
  objects.block1.mass = 10
  objects.block1.body:setMass(objects.block1.mass)
  objects.block1.shape = love.physics.newRectangleShape(0, 0, 50, 100)
  objects.block1.fixture = love.physics.newFixture(objects.block1.body, objects.block1.shape)

  border = assets.img.border
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

  -- create road
  road:load(player.body:getX()-50, player.body:getY(), 8, 128)
  paveThreshold = road:getPaveThreshold()

  love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
  love.window.setMode(width, height)

  if ctx:getArg('connect') then
    netman:client()
    netman:connect(ctx:getArg('connect'), ctx.DEFAULT_PORT)
  else
    netman:host()
  end
end

-- server handlers
function love.handlers.netmanPlayerJoinRequest(id)
  -- let everyone in
  netman:welcome(id)
end

function love.handlers.netmanPlayerJoined(id)
  logger:info("player %s has joined", id)
end

function love.handlers.netmanPlayerLeft(id)
  logger:info("player %s has left", id)
end

-- client handlers
function love.handlers.netmanConnected(rc)
  netman:join(player:getId())
end

function love.handlers.netmanJoined(id, text)
  logger:info("joined as player %s: %s", id, text)
end

function love.handlers.netmanRejected(id, text)
  logger:info("player %s could not join: %s", id, text)
end

function love.handlers.netmanDisconnected(rc)
end

-- common handlers
function love.handlers.netmanRecvCoord(id, coord)
  logger:debug("player %s @ x: %f; y: %f", id, coord.x, coord.y)
end

function love.update(dt)
  if world then
    world:update(dt) -- put the world in motion!
  end

  camera:move(player.dx, player.dy)

  player:update(ground, dt)

  -- detect if player is triggering new road creation and calculate location of new road
  distance = love.physics.getDistance(player.fixture, road.frontier.main.fixture)
  -- collided with frontier
  while distance < paveThreshold do
    -- paving new road
    leftDistance = love.physics.getDistance(player.fixture, road.frontier.left.fixture)
    rightDistance = love.physics.getDistance(player.fixture, road.frontier.right.fixture)
    if leftDistance < paveThreshold then
      roadShift = "left"
    elseif rightDistance < paveThreshold then
      roadShift = "right"
    else
      roadShift = "center"
    end
    road:update(player:getTrajectory(), roadShift)
    distance = love.physics.getDistance(player.fixture, road.frontier.main.fixture)
  end

  netman:sendCoord(player)
end

function love.draw()
  camera:set()

  ground:draw()
  love.graphics.setColor(0.28, 0.64, 0.05)
  love.graphics.polygon("fill",
    objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(objects.borderTop.img, objects.borderTop.quad, 0, 0)

  love.graphics.draw(objects.borderBottom.img, objects.borderBottom.quad, 0, objects.borderBottom.body:getY(), 0, 1, -1)

  road:draw()

  player:draw()

  camera:unset()
end

function love.filedropped(file)
  player.img = love.graphics.newImage(file)
end
