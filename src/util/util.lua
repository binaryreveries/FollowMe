require("love.math")

local NUM_MAX = 4503599627370495 -- 2^52 - 1

local util = {}

function util:randNum()
  return love.math.random(NUM_MAX)
end

function util:randHex()
  return string.format("%x", util:randNum())
end

function util:dotProduct(x1, y1, x2, y2)
  return x1 * x2 + y1 * y2
end

function util:clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

return util
