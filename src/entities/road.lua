local assets = require "assets"
local road = {}

-- create ground
function road:load(player, width, height)
  self.roadjog = 40
  self.segments = {}
  self.skin = assets.img.road
  self:addsegment(player)

  self.frontier = {}
  self.frontier.body = love.physics.newBody(world)
  self.frontier.body:setX(player.body:getX()-50)
  self.frontier.body:setY(player.body:getY())
  self.frontier.shape = love.physics.newRectangleShape(self.segments[1].width,
                                                       self.segments[1].height)
  self.frontier.fixture = love.physics.newFixture(self.frontier.body,
                                                  self.frontier.shape)
  self.frontier.fixture:setSensor(true)
end

function road:draw()
  for _, segment in pairs(self.segments) do
    love.graphics.draw(segment.img,
                       segment.body:getX(),
                       segment.body:getY(), -- need to shift so that car is in center, using width, height and angle
                       segment.body:getAngle())
  end
  love.graphics.polygon("fill",
    self.frontier.body:getWorldPoints(self.frontier.shape:getPoints())
  )
end

function road:update(player, dt)
  -- detect if player is triggering new road creation and calculate location of new road
  self.distance = love.physics.getDistance(player.fixture, self.frontier.fixture)
  if (self.distance < self.roadjog/10) then
    self.frontier.body:setAngle(player.trajectory)
    fy = (self.roadjog) * math.sin(self.frontier.body:getAngle())
    fx = (self.roadjog) * math.cos(self.frontier.body:getAngle())
    self.frontier.body:setX(player.body:getX() + fx)
    self.frontier.body:setY(player.body:getY() + fy)
    self:addsegment(player)
  end
end

-- utils

function road:addsegment(leader)
  segment = {}
  segment.img = self.skin
  segment.width = segment.img:getWidth()
  segment.height = segment.img:getHeight()
  segment.body = love.physics.newBody(world)
  segment.body:setAngle(leader.trajectory)
  fx = math.sin(segment.body:getAngle()) * (segment.height/2)
  fy = math.cos(segment.body:getAngle()) * -(segment.height/2)
  segment.body:setX(leader.body:getX() + fx)
  segment.body:setY(leader.body:getY() + fy)
  segment.shape = love.physics.newRectangleShape(0, 0, segment.width, segment.height)
  table.insert(self.segments, segment)
end

return road
