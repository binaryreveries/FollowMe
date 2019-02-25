local ctx = {}

ctx.DEFAULT_PORT = 424242
ctx.GLOBAL_CTX_MANAGER_CODE = "gamectx/global_manager.lua"
ctx.GLOBAL_CTX_REQ_CHAN = 'ctxReq'
ctx.NET_TICKS_S = 1
ctx.NET_TIMEOUT_S = 5
ctx.NET_BIND_RETRY_COUNT = 5
ctx.NET_BIND_RETRY_INTERVAL_S = 1

local reqChan = love.thread.getChannel(ctx.GLOBAL_CTX_REQ_CHAN)
local respChan = love.thread.newChannel()

function ctx:set(key, val)
  reqChan:push({action='set', key=key, val=val})
end

function ctx:get(key)
  reqChan:push({action='get', key=key, respChan=respChan})
  return respChan:demand()
end

function ctx:setArg(key, val)
  reqChan:push({action='setArg', key=key, val=val})
end

function ctx:getArg(key)
  reqChan:push({action='getArg', key=key, respChan=respChan})
  return respChan:demand()
end

function ctx:getArgs()
  reqChan:push({action='getArgs', respChan=respChan})
  return respChan:demand()
end

function ctx:load()
  local t = love.thread.newThread(ctx.GLOBAL_CTX_MANAGER_CODE)
  t:start(reqChan)
end

return ctx
