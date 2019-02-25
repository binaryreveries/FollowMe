require("love.math")

local NUM_MAX = 4503599627370495 -- 2^52 - 1

local util = {}

function util:randNum()
  return love.math.random(NUM_MAX)
end

function util:randHex()
  return string.format("%x", util:randNum())
end

return util
