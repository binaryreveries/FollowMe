local logger = require("logger/logger")

local argparse = {}

function argparse:parse(raw)
  local args = {}

  function parse_flag(flag)
    for i=1,#raw do
      if raw[i] == '--' .. flag then
        args[flag] = true
        return
      end
    end
  end

  function parse_value(option)
    for i=1,#raw do
      if raw[i] == '--' .. option then
        if i + 1 > #raw then
          logger:fatal("argument '%s' is missing value", raw[i])
        end
        args[option] = raw[i + 1]
        return
      end
    end
  end

  parse_flag('debug')
  parse_value('connect')

  return args
end

return argparse
