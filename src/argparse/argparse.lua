local ctx = require("gamectx.global")
local logger = require("logger.logger")

local argparse = {}

function argparse:parse(args)
  local function parseFlag(flag)
    for i=1,#args do
      if args[i] == '--' .. flag then
        ctx:setArg(flag, true)
        return
      end
    end
  end

  local function parseValue(option)
    for i=1,#args do
      if args[i] == '--' .. option then
        if i + 1 > #args then
          logger:fatal("argument '%s' is missing value", args[i])
        end
        ctx:setArg(option, args[i + 1])
        return
      end
    end
  end

  parseFlag('debug')
  parseValue('connect')
end

return argparse
