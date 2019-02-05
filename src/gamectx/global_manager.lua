local ctx = require("gamectx/global")
local logger = require("logger/logger")
local req_chan = ...

local args = { -- populated by argparse
  debug=nil,
  connect=nil,
}

local opts = {
  debug_enabled=false,
}

local function arg_to_opt(key, val)
  if key == 'debug' then
    opts.debug_enabled = true
  end
end

while true do
  local data = req_chan:demand()
  if data.action == 'set' then
    opts[data.key] = data.val
  elseif data.action == 'get' then
    data.resp_chan:push(opts[data.key])
  elseif data.action == 'set_arg' then
    args[data.key] = data.val
    arg_to_opt(data.key, data.val)
  elseif data.action == 'get_arg' then
    data.resp_chan:push(args[data.key])
  elseif data.action == 'get_args' then
    data.resp_chan:push(args)
  else
    logger:fatal("unrecognized action: %s", data.action)
  end
end
