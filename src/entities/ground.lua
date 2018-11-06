local assets = require "assets"
local ground = {}

-- create ground
function ground:load(width, height)
  self.body = love.physics.newBody(world, width/2, height/2)
  self.shape = love.physics.newRectangleShape(width, height)
end

function ground:draw()
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.polygon("fill",
    self.body:getWorldPoints(self.shape:getPoints()))
end

return ground
