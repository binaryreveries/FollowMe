local GLOBAL_CTX_MANAGER_CODE = "gamectx/global_manager.lua"

local ctx = {}

local GLOBAL_CTX_REQ_CHAN = 'ctx_req'
local req_chan = love.thread.getChannel(GLOBAL_CTX_REQ_CHAN)
local resp_chan = love.thread.newChannel()

function ctx:set(key, val)
  req_chan:push({action='set', key=key, val=val})
end

function ctx:get(key)
  req_chan:push({action='get', key=key, resp_chan=resp_chan})
  return resp_chan:demand()
end

function ctx:set_arg(key, val)
  req_chan:push({action='set_arg', key=key, val=val})
end

function ctx:get_arg(key)
  req_chan:push({action='get_arg', key=key, resp_chan=resp_chan})
  return resp_chan:demand()
end

function ctx:get_args()
  req_chan:push({action='get_args', resp_chan=resp_chan})
  return resp_chan:demand()
end

function ctx:load()
  local t = love.thread.newThread(GLOBAL_CTX_MANAGER_CODE)
  t:start(req_chan)
end

return ctx
