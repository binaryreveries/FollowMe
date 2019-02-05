local ctx = require("gamectx/global")
local logger = require("logger/logger")

local argparse = {}

function argparse:parse(args)
  local function parse_flag(flag)
    for i=1,#args do
      if args[i] == '--' .. flag then
        ctx:set_arg(flag, true)
        return
      end
    end
  end

  local function parse_value(option)
    for i=1,#args do
      if args[i] == '--' .. option then
        if i + 1 > #args then
          logger:fatal("argument '%s' is missing value", args[i])
        end
        ctx:set_arg(option, args[i + 1])
        return
      end
    end
  end

  parse_flag('debug')
  parse_value('connect')
end

return argparse
