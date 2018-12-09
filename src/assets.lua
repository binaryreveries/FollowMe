local assets = {}

local basedir = "assets"

assets.img = {}
assets.img.border = love.graphics.newImage(basedir .. "/border.png")
assets.img.car = love.graphics.newImage(basedir .. "/car.png")
assets.img.road = love.graphics.newImage(basedir .. "/road.png")
assets.img.treecar = love.graphics.newImage(basedir .. "/treecar.png")

return assets
