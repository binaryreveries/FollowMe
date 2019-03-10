local assets = require("assets")
local netman = require("net.netman")
local road = {}

-- initialize road at (x, y) with each segment of given width and length
function road:load(x, y, width, length)
  -- Road paving is accompished in each update by moving and rotating the
  -- frontier forward. We need to ensure that all parts of the new frontier
  -- position are in front of the old position. We can think of these two
  -- positions as the two legs of an isosceles triangle. The base of the
  -- triangle represents the start and end points of the travel of the center of
  -- the frontier. The legs represent half of frontier object. In this way we
  -- ensure that the turn of the frontier is never so accute that it crosses the
  -- previous position. We define pivot length, which represents the legs of the
  -- triangle, to be 0.6 the length of the frontier. This is a little longer
  -- than half the length of the frontier, which creates smoother curves.
  -- We define the base of the triangle as roadPush/2. We define our rotation
  -- limit as atan2 of the sin and cos of the angle, which we find using
  -- triginometic functions.
  self.paveThreshold = 0.1
  self.roadPush = 1
  self.roadSlide = self.roadPush/5
  self.pivotLength = length * 0.6
  local sinLimit = (self.roadPush/2) / self.pivotLength
  local cosLimit = math.sqrt(self.pivotLength^2 - self.roadPush/2) / self.pivotLength
  self.rotationLimit = math.pi - (math.abs(math.atan2(cosLimit, sinLimit)) * 2)

  -- the road is comprised of two major components: segments, which are a series
  -- of rectangular objects, and the frontier, which is a trigger that is
  -- activated when a player drives near it. The touching the frontier creates a
  -- new segment and moves the frontier forward. The frontier is made of of the
  -- main, left and right frontier. The main fontier handles the main movment,
  -- while the left and right frontiers detect which side of the track the
  -- player is on.
  self.segments = {}
  self.segmentsData = {} -- original coordinates that created self.segments
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
  love.graphics.setColor(255, 255, 255, 255)
end

-- utils
function road:addSegment(segmentData)
  local segment = {}
  segment.img = self.skin
  segment.width = segment.img:getWidth()
  segment.height = segment.img:getHeight()
  segment.body = love.physics.newBody(world)
  segment.body:setAngle(segmentData.angle)
  local fx = math.sin(segment.body:getAngle()) * (segment.height/2)
  local fy = math.cos(segment.body:getAngle()) * -(segment.height/2)
  segment.body:setX(segmentData.x + fx)
  segment.body:setY(segmentData.y + fy)
  segment.shape = love.physics.newRectangleShape(0, 0, segment.width, segment.height)
  table.insert(self.segments, segment)
  table.insert(self.segmentsData, segmentData)
end

function road:addSegments(segmentsData)
  if not segmentsData then
    return
  end
  for _, segmentData in ipairs(segmentsData) do
    self:addSegment(segmentData)
  end
end

function road:getSegmentsData()
  return self.segmentsData
end

function road:getPaveThreshold()
  return self.paveThreshold
end

local function getLeftAngle(angle)
  return (angle - math.pi / 2) % (2 * math.pi)
end

local function getRightAngle(angle)
  return (angle + math.pi / 2) % (-2 * math.pi)
end

function road:getDeltaLeft(angle)
  local leftAngle = getLeftAngle(angle)
  local deltaLeftX = self.frontier.main.length / 3 * math.cos(leftAngle)
  local deltaLeftY = self.frontier.main.length / 3 * math.sin(leftAngle)
  return deltaLeftX, deltaLeftY
end

function road:getDeltaRight(angle)
  local rightAngle = getRightAngle(angle)
  local deltaRightX = self.frontier.main.length / 3 * math.cos(rightAngle)
  local deltaRightY = self.frontier.main.length / 3 * math.sin(rightAngle)
  return deltaRightX, deltaRightY
end

function road:pushFrontierOne(p, roadShift)
  local angle = p:getTrajectory()
  -- Radians in love range between pi and -pi. To ensure that we never have
  -- angles outside this range, we check if abs(deltaAngle) is greater than pi.
  -- This can happen when crossing the pi/-pi theshold (e.g. the delta between
  -- angles 3 and -3)  If this happens so we adjust our angle so that we are
  -- within the range of values accepted.
  local lastAngle = self.frontier.main.body:getAngle()
  local deltaAngle = lastAngle - angle
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

  -- here we apply the rotation limit to our angle. If the change in angle of
  -- our frontier (deltaAngle) is grater then our rotation limit, then we cap
  -- the change in angle by adjusting our last angle by the rotation limit.
  if math.abs(deltaAngle) > self.rotationLimit then
    if deltaAngle > 0 then
      angle = lastAngle - self.rotationLimit
    else
      angle = lastAngle + self.rotationLimit
    end
  end

  -- Get the old frontier position, and calculate the new position based on the
  -- new angle.
  local x = self.frontier.main.body:getX() + (self.roadPush) * math.cos(angle)
  local y = self.frontier.main.body:getY() + (self.roadPush) * math.sin(angle)
  
  -- if the player is near the edge of the frontier, calculate deltaSlides,
  -- which shift the frontier perpendicular to the trajectory of the player to
  -- center the frontier infront of the player.
  local deltaSlideX = nil
  local deltaSlideY = nil
  if roadShift == "center" then
    deltaSlideX = 0
    deltaSlideY = 0
  else
    local slideAngle = nil
    if roadShift == "left" then
      slideAngle = getLeftAngle(angle)
    elseif roadShift == "right" then
      slideAngle = getRightAngle(angle)
    end
    deltaSlideX = self.roadSlide * math.cos(slideAngle)
    deltaSlideY = self.roadSlide * math.sin(slideAngle)
  end

  local frontierData = {x=(x + deltaSlideX), y=(y + deltaSlideY), angle=angle}
  self:setFrontier(frontierData)

  return frontierData
end

function road:pushFrontier(p)
  -- detect if player is triggering new road creation and calculate location of new road
  local distance = love.physics.getDistance(p.fixture, road.frontier.main.fixture)
  -- collided with frontier
  local newSegmentsData = {}
  while distance < paveThreshold do
    -- paving new road
    local leftDistance = love.physics.getDistance(p.fixture, road.frontier.left.fixture)
    local rightDistance = love.physics.getDistance(p.fixture, road.frontier.right.fixture)
    local roadShift
    if leftDistance < paveThreshold then
      roadShift = "left"
    elseif rightDistance < paveThreshold then
      roadShift = "right"
    else
      roadShift = "center"
    end
    local frontierData = road:pushFrontierOne(p, roadShift)
    table.insert(newSegmentsData, frontierData)
    distance = love.physics.getDistance(p.fixture, road.frontier.main.fixture)
  end
  self:addSegments(newSegmentsData)

  if #newSegmentsData > 0 then
    return newSegmentsData
  end
end

function road:setFrontier(frontierData)
  if not frontierData then
    return
  end
  local x, y, angle = frontierData.x, frontierData.y, frontierData.angle

  -- calculate positions of left and right frontiers relative to the new main
  -- frontier.
  local deltaLeftX, deltaLeftY = self:getDeltaLeft(angle)
  local deltaRightX, deltaRightY = self:getDeltaRight(angle)

  -- apply all transformations to the frontiers.
  self.frontier.main.body:setX(x)
  self.frontier.main.body:setY(y)
  self.frontier.left.body:setX(x + deltaLeftX)
  self.frontier.left.body:setY(y + deltaLeftY)
  self.frontier.right.body:setX(x + deltaRightX)
  self.frontier.right.body:setY(y + deltaRightY)
  
  -- Set angles of all frontier objects to the new angle
  self.frontier.main.body:setAngle(angle)
  self.frontier.left.body:setAngle(angle)
  self.frontier.right.body:setAngle(angle)
end

return road
