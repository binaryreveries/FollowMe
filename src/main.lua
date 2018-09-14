-- FollowMe
-- Move car around using the arrow keys.
-- Compatible with löve 0.6.0 and up

function love.load()
  car = love.graphics.newImage("car.png")
  x = 50
  y = 50
  speed = 300
end

function love.update(dt)
  if love.keyboard.isDown("w") then
    y = y - (speed * dt)
  end
  if love.keyboard.isDown("s") then
    y = y + (speed * dt)
  end
  if love.keyboard.isDown("a") then
    x = x - (speed * dt)
  end
  if love.keyboard.isDown("d") then
    x = x + (speed * dt)
  end
end

function love.draw()
  love.graphics.draw(car, x, y)
end
