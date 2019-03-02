local assets = require("assets")
local ground = {}

-- create ground
function ground:load(x, y, width, height)
  self.body = love.physics.newBody(world, x, y)
  self.shape = love.physics.newRectangleShape(width, height)
end

function ground:draw()
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.polygon("fill",
    self.body:getWorldPoints(self.shape:getPoints()))
end

return ground
