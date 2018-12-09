local assets = require "assets"
local road = {}

-- initialize road at (x, y) with each segment of given width and length
function road:load(x, y, width, length)
  self.roadjog = 40
  self.segments = {}
  self.skin = assets.img.road

  self.frontier = {}
  self.frontier.body = love.physics.newBody(world)
  self.frontier.body:setX(x)
  self.frontier.body:setY(y)
  self.frontier.shape = love.physics.newRectangleShape(width, length)
  self.frontier.fixture = love.physics.newFixture(self.frontier.body,
                                                  self.frontier.shape)
  self.frontier.fixture:setSensor(true)
end

function road:draw()
  for _, segment in pairs(self.segments) do
    love.graphics.draw(segment.img,
                       segment.body:getX(),
                       segment.body:getY(),
                       segment.body:getAngle())
  end
  love.graphics.polygon("fill",
    self.frontier.body:getWorldPoints(self.frontier.shape:getPoints())
  )
end

function road:update(x, y, angle)
  self.frontier.body:setAngle(angle)
  fy = (self.roadjog) * math.sin(self.frontier.body:getAngle())
  fx = (self.roadjog) * math.cos(self.frontier.body:getAngle())
  self.frontier.body:setX(x + fx)
  self.frontier.body:setY(y + fy)
  self:addsegment()
end

-- utils

function road:addsegment()
  segment = {}
  segment.img = self.skin
  segment.width = segment.img:getWidth()
  segment.height = segment.img:getHeight()
  segment.body = love.physics.newBody(world)
  segment.body:setAngle(self.frontier.body:getAngle())
  fx = math.sin(segment.body:getAngle()) * (segment.height/2)
  fy = math.cos(segment.body:getAngle()) * -(segment.height/2)
  segment.body:setX(self.frontier.body:getX() + fx)
  segment.body:setY(self.frontier.body:getY() + fy)
  segment.shape = love.physics.newRectangleShape(0, 0, segment.width, segment.height)
  table.insert(self.segments, segment)
end

return road
