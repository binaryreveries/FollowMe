-- FollowMe
-- Move car around using the arrow keys.
-- Compatible with löve 0.10.0 and up

world = nil

local assets = nil
local block1 = nil
local border = nil
local ground = nil
local height = 650
local player = nil
local road = nil
local width = 650

function love.load()
  assets = require "assets" -- load assets
  love.physics.setMeter(16) -- length of a meter in our world is 16px
  world = love.physics.newWorld(0, 0, true) -- create a world with no horizontal or vertical gravity

  -- create ground
  ground = require "entities/ground"
  ground:load(width, height)

  -- create car
  player = require "entities/player"
  player:load(width, height)

  objects = {}
  objects.block1 = {}
  objects.block1.body = love.physics.newBody(world, 200, 300, "dynamic")
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
  road = require "entities/road"
  road:load(player, width, height)
  
  love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
  love.window.setMode(width, height)
end

function love.update(dt)
  if world then
    world:update(dt) -- put the world in motion!
  end

  player:update(ground, dt)

  -- paving new road
  road:update(player, dt)
end

function love.draw()
  ground:draw()
  love.graphics.setColor(0.28, 0.64, 0.05)
  love.graphics.polygon("fill",
    objects.block1.body:getWorldPoints(objects.block1.shape:getPoints()))

  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(objects.borderTop.img, objects.borderTop.quad, 0, 0)

  love.graphics.draw(objects.borderBottom.img, objects.borderBottom.quad, 0, objects.borderBottom.body:getY(), 0, 1, -1)

  road:draw()

  player:draw()
end

function love.filedropped(file)
  player.img = love.graphics.newImage(file)
end
