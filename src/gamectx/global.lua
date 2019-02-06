local GLOBAL_CTX_MANAGER_CODE = "gamectx/global_manager.lua"

local ctx = {}

local GLOBAL_CTX_REQ_CHAN = 'ctxReq'
local reqChan = love.thread.getChannel(GLOBAL_CTX_REQ_CHAN)
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
  local t = love.thread.newThread(GLOBAL_CTX_MANAGER_CODE)
  t:start(reqChan)
end

return ctx
