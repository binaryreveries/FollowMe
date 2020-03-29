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

local isServer = false

local playerLocal
local playersById = {}

function love.load(args)
  ctx:load()
  argparse:parse(args)
  logger:debug("debug mode enabled")
  for k, v in pairs(ctx:getArgs()) do
    logger:debug("\t%s -> %s", k, v)
  end

  love.physics.setMeter(1) -- length of a meter in our world is 1px
  world = love.physics.newWorld(0, 0, true) -- create a world with no horizontal or vertical gravity

  assets:load()
  camera:load()
  ground:load(width, height)

  playerLocal = player:create(width / 2, height / 2)
  playersById[playerLocal:getId()] = playerLocal

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
  road:load(playerLocal.body:getX()-50, playerLocal.body:getY(), 8, 128)
  paveThreshold = road:getPaveThreshold()

  love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
  love.window.setMode(width, height)

  isServer = not ctx:getArg('connect')
  if isServer then
    netman:host()
  else
    netman:client()
    netman:connect(ctx:getArg('connect'), ctx.DEFAULT_PORT)
  end
end

-- server handlers
function love.handlers.netmanPlayerJoinRequest(id)
  -- let everyone in
  local coordsById = {}
  for id, p in pairs(playersById) do
    coordsById[id] = p:getCoord()
  end
  netman:welcome(id, coordsById, road:getSegmentsData())
end

-- client handlers
function love.handlers.netmanConnected(rc)
  netman:join(playerLocal:getId())
end

function love.handlers.netmanJoined(id, text)
  logger:info("joined as player %s: %s", id, text)
end

function love.handlers.netmanRejected(id, text)
  logger:info("player %s could not join: %s", id, text)
end

function love.handlers.netmanDisconnected(rc)
  for id in pairs(playersById) do
    if id ~= playerLocal:getId() then
      love.event.push('netmanPlayerLeft', id)
    end
  end
end

-- common handlers
function love.handlers.netmanPlayerJoined(id, coord)
  if id == playerLocal:getId() then
    return
  end

  logger:info("player %s has joined", id)
  local p = player:create(width / 2, height / 2, id)
  if coord then
    p:setCoord(coord)
  end
  playersById[id] = p

  if isServer then
    netman:announcePlayerJoined(id, coord)
  end
end

function love.handlers.netmanPlayerLeft(id)
  logger:info("player %s has left", id)
  playersById[id]:destroy()
  playersById[id] = nil

  if isServer then
    netman:announcePlayerLeft(id)
  end
end

function love.handlers.netmanRecvCoord(id, coord)
  local p = playersById[id]
  if not p or p:getId() == playerLocal:getId() then
    return
  end
  p:setCoord(coord)
end

function love.handlers.netmanRecvPlayerSprite(id, sprite)
  logger:info("player %s has changed sprite", id)
  local p = playersById[id]
  if not p or p:getId() == playerLocal:getId() then
    return
  end
  p:setSpriteFromData(sprite)

  if isServer then
    netman:announcePlayerSprite(id, sprite)
  end
end

function love.update(dt)
  if world then
    world:update(dt) -- put the world in motion!
  end

  for _, p in pairs(playersById) do
    p:update(dt)
    if isServer then
      local segmentsData = road:pushFrontier(p)
      netman:sendRoadData(segmentsData)
    end
  end

  if not isServer then -- client
    local frontierData, segmentsData = netman:recvRoadData()
    road:setFrontier(frontierData)
    road:addSegments(segmentsData)
  end

  camera:setPosition(playerLocal:getPosition())
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

  for _, p in pairs(playersById) do
    p:draw()
  end

  camera:unset()
end

function love.filedropped(file)
  local data = love.image.newImageData(file)
  local img = love.graphics.newImage(data)
  playerLocal:setSprite(img)
  local id = playerLocal:getId()
  local sprite = {
    format=data:getFormat(),
    data=data:getString()
  }
  if isServer then
    netman:announcePlayerSprite(id, sprite)
  else
    netman:sendPlayerSprite(id, sprite)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "w" then
    playerLocal:beginAccelerating()
  elseif key == "s" then
    playerLocal:beginReversing()
  elseif key == "a" then
    playerLocal:beginTurningLeft()
  elseif key == "d" then
    playerLocal:beginTurningRight()
  elseif key == "space" then
    playerLocal:beginBraking()
  end
end

function love.keyreleased(key, scancode)
  if key == "w" then
    playerLocal:endAccelerating()
  elseif key == "s" then
    playerLocal:endReversing()
  elseif key == "a" then
    playerLocal:endTurningLeft()
  elseif key == "d" then
    playerLocal:endTurningRight()
  elseif key == "space" then
    playerLocal:endBraking()
  end
end

function love.quit()
  if isServer then
    netman:announceShutdown()
  else
    netman:leave(playerLocal:getId())
  end
end
