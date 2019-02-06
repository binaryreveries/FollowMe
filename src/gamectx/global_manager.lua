local ctx = require("gamectx/global")
local logger = require("logger/logger")
local reqChan = ...

local args = { -- populated by argparse
  debug=nil,
  connect=nil,
}

local opts = {
  debugEnabled=false,
}

local function argToOpt(arg)
  if arg == 'debug' then
    opts.debugEnabled = args[arg]
  end
end

while true do
  local data = reqChan:demand()
  if data.action == 'set' then
    opts[data.key] = data.val
  elseif data.action == 'get' then
    data.respChan:push(opts[data.key])
  elseif data.action == 'setArg' then
    args[data.key] = data.val
    argToOpt(data.key)
  elseif data.action == 'getArg' then
    data.respChan:push(args[data.key])
  elseif data.action == 'getArgs' then
    data.respChan:push(args)
  else
    logger:fatal("unrecognized action: %s", data.action)
  end
end
