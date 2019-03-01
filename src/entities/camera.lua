local camera = {}

function camera:load()
  self.x = 0
  self.y = 0
  self.scaleX = 1
  self.scaleY = 1
  self.rotation = 0
end

function camera:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
  love.graphics.translate(love.graphics.getWidth() / 2 * self.scaleX - self.x,
                          love.graphics.getHeight() / 2 * self.scaleY - self.y)
end

function camera:unset()
  love.graphics.pop()
end

function camera:rotate(dr)
  self.rotation = self.rotation + dr
end

function camera:scale(sx, sy)
  sx = sx or 1
  self.scaleX = self.scaleX * sx
  self.scaleY = self.scaleY * (sy or sx)
end

function camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function camera:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end

return camera
