local assets = require "assets"
local road = {}

-- initialize road at (x, y) with each segment of given width and length
function road:load(x, y, width, length)
  self.roadPush = 1
  self.roadSlide = self.roadPush/5
  self.pivotLength = length * 0.6
  sinLimit = (self.roadPush/2) / self.pivotLength
  cosLimit = math.sqrt(self.pivotLength^2 - self.roadPush/2) / self.pivotLength
  self.rotationLimit = math.pi - (math.abs(math.atan2(cosLimit, sinLimit)) * 2)
  
  self.segments = {}
  self.skin = assets.img.road
  
  self.frontier = {}
  self.frontier.main = {}
  self.frontier.main.body = love.physics.newBody(world)
  self.frontier.main.body:setX(x)
  self.frontier.main.body:setY(y)
  self.frontier.main.body:setAngle(math.pi)
  self.frontier.main.shape = love.physics.newRectangleShape(width, length)
  self.frontier.main.fixture = love.physics.newFixture(self.frontier.main.body,
                                                  self.frontier.main.shape)
  self.frontier.main.fixture:setSensor(true)
  self.frontier.main.length = length
  
  self.frontier.left = {}
  self.frontier.left.body = love.physics.newBody(world)
  self.frontier.left.body:setX(x)
  self.frontier.left.body:setY(y+length/3)
  self.frontier.left.shape = love.physics.newRectangleShape(width, length/3)
  self.frontier.left.fixture = love.physics.newFixture(self.frontier.left.body,
                                                  self.frontier.left.shape)
  self.frontier.left.fixture:setSensor(true)

  self.frontier.right = {}
  self.frontier.right.body = love.physics.newBody(world)
  self.frontier.right.body:setX(x)
  self.frontier.right.body:setY(y-length/3)
  self.frontier.right.shape = love.physics.newRectangleShape(width, length/3)
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
  love.graphics.setColor(0, 255, 0, 255)
  love.graphics.polygon("fill",
    self.frontier.right.body:getWorldPoints(self.frontier.right.shape:getPoints())
  )
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.polygon("fill",
    self.frontier.left.body:getWorldPoints(self.frontier.left.shape:getPoints())
  )

end

function road:update(angle, roadShift)
  self:addsegment()

  mainX = self.frontier.main.body:getX()
  mainY = self.frontier.main.body:getY()
  
  lastAngle = self.frontier.main.body:getAngle()
  deltaAngle = lastAngle - angle
  if math.abs(deltaAngle) > math.pi then
    if deltaAngle > 0 then
      deltaAngle = deltaAngle - 2 * math.pi
    else
      deltaAngle = deltaAngle + 2 * math.pi
    end
  end
  
  if math.abs(deltaAngle) > math.pi/2 then
    --car crashes? this should never happen unless people get off the track
  end
  
  if math.abs(deltaAngle) > self.rotationLimit then
    if deltaAngle > 0 then
      angle = lastAngle - self.rotationLimit
    else
      angle = lastAngle + self.rotationLimit
    end
  end
  
  self.frontier.main.body:setAngle(angle)  
  deltaMainX = (self.roadPush) * math.cos(angle)
  deltaMainY = (self.roadPush) * math.sin(angle)
  self.frontier.left.body:setAngle(angle)
  leftAngle = angle - (math.pi/2)
  if leftAngle < -math.pi then leftAngle = leftAngle + 2 * math.pi end
  deltaLeftX = self.frontier.main.length/3 * math.cos(leftAngle)
  deltaLeftY = self.frontier.main.length/3 * math.sin(leftAngle)
  self.frontier.right.body:setAngle(angle)
  rightAngle = angle + (math.pi/2)
  if rightAngle > math.pi then rightAngle = rightAngle - 2 * math.pi end
  deltaRightX = self.frontier.main.length/3 * math.cos(rightAngle)
  deltaRightY = self.frontier.main.length/3 * math.sin(rightAngle)
  
  if roadShift == "center" then
    deltaSlideX = 0
    deltaSlideY = 0
    slideAngle = 0
  else
    if roadShift == "left" then
      slideAngle = leftAngle
    elseif roadShift == "right" then
      slideAngle = rightAngle
    end
    deltaSlideX = self.roadSlide * math.cos(slideAngle)
    deltaSlideY = self.roadSlide * math.sin(slideAngle)
  end
  
  self.frontier.main.body:setX(mainX + deltaMainX + deltaSlideX)
  self.frontier.main.body:setY(mainY + deltaMainY + deltaSlideY)
  self.frontier.left.body:setX(mainX + deltaMainX + deltaLeftX + deltaSlideX)
  self.frontier.left.body:setY(mainY + deltaMainY + deltaLeftY + deltaSlideY)
  self.frontier.right.body:setX(mainX + deltaMainX + deltaRightX + deltaSlideX)
  self.frontier.right.body:setY(mainY + deltaMainY + deltaRightY + deltaSlideY)
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
