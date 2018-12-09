local assets = require "assets"
local road = {}

-- initialize road at (x, y) with each segment of given width and length
function road:load(x, y, width, length)
  self.roadjog = 1
  self.segments = {}
  self.skin = assets.img.road
  
  self.frontier = {}
  
  self.frontier.main = {}
  self.frontier.main.body = love.physics.newBody(world)
  self.frontier.main.body:setX(x)
  self.frontier.main.body:setY(y)
  self.frontier.main.shape = love.physics.newRectangleShape(width, length)
  self.frontier.main.fixture = love.physics.newFixture(self.frontier.main.body,
                                                  self.frontier.main.shape)
  self.frontier.main.fixture:setSensor(true)
  self.frontier.main.deltaAngle = self.frontier.main.body:getAngle()
  
  self.frontier.left = {}
  self.frontier.left.body = love.physics.newBody(world)
  self.frontier.left.body:setX(x)
  self.frontier.left.body:setY(y+length/4)
  self.frontier.left.shape = love.physics.newRectangleShape(width, length/2)
  self.frontier.left.fixture = love.physics.newFixture(self.frontier.left.body,
                                                  self.frontier.left.shape)
  self.frontier.left.fixture:setSensor(true)

  
  self.frontier.right = {}
  self.frontier.right.body = love.physics.newBody(world)
  self.frontier.right.body:setX(x)
  self.frontier.right.body:setY(y-length/4)
  self.frontier.right.shape = love.physics.newRectangleShape(width, length/2)
  self.frontier.right.fixture = love.physics.newFixture(self.frontier.right.body,
                                                  self.frontier.right.shape)
  self.frontier.right.fixture:setSensor(true)

end

function road:draw()
  for _, segment in pairs(self.segments) do
    love.graphics.draw(segment.img,
                       segment.body:getX(),
                       segment.body:getY(),
                       segment.body:getAngle())
  end
  love.graphics.polygon("fill",
    self.frontier.main.body:getWorldPoints(self.frontier.main.shape:getPoints())
  )
  
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.polygon("fill",
    self.frontier.left.body:getWorldPoints(self.frontier.left.shape:getPoints())
  )
  love.graphics.setColor(0, 255, 0, 255)
  love.graphics.polygon("fill",
    self.frontier.right.body:getWorldPoints(self.frontier.right.shape:getPoints())
  )
end

function road:update(angle)
  self.frontier.main.deltaAngle = angle - self.frontier.main.body:getAngle()
  self.frontier.main.body:setAngle(angle)
  x = self.frontier.main.body:getX()
  y = self.frontier.main.body:getY()
  fy = (self.roadjog) * math.sin(self.frontier.main.body:getAngle())
  fx = (self.roadjog) * math.cos(self.frontier.main.body:getAngle())
  self.frontier.main.body:setX(x + fx)
  self.frontier.main.body:setY(y + fy)
  self:addsegment()
end

-- utils

function road:addsegment()
  segment = {}
  segment.img = self.skin
  segment.width = segment.img:getWidth()
  segment.height = segment.img:getHeight()
  segment.body = love.physics.newBody(world)
  segment.body:setAngle(self.frontier.main.body:getAngle())
  fx = math.sin(segment.body:getAngle()) * (segment.height/2)
  fy = math.cos(segment.body:getAngle()) * -(segment.height/2)
  segment.body:setX(self.frontier.main.body:getX() + fx)
  segment.body:setY(self.frontier.main.body:getY() + fy)
  segment.shape = love.physics.newRectangleShape(0, 0, segment.width, segment.height)
  table.insert(self.segments, segment)
end

return road
