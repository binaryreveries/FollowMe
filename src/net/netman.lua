local ctx = require("gamectx.global")
local logger = require("logger.logger")

local netman = {}

local CLIENT_CODE = "net/client.lua"
local SERVER_CODE = "net/server.lua"

-- types of commands
netman.CMD_CONNECT = 1
netman.CMD_JOIN = 2
netman.CMD_LEAVE = 3
netman.CMD_WELCOME = 4
netman.CMD_STOP = 5

-- types of data we can request to send
netman.SEND_COORD = 1

-- disconnect reasons
netman.DISCONNECT_LEFT = 0
netman.DISCONNECT_BAD_VERSION = 1

local cmdChan = nil -- command channel
local sendChan = nil -- outgoing data channel
local netThread = nil -- thread responsible networking

local function startNetThread(code)
  if netThread then
    logger:info("cleaning up old netman thread")
    netman:stop()
  end
  netThread = love.thread.newThread(code)
  cmdChan = love.thread.newChannel()
  sendChan = love.thread.newChannel()
  netThread:start(netThread, cmdChan, sendChan)
end

function netman:host()
  startNetThread(SERVER_CODE)
end

function netman:client()
  startNetThread(CLIENT_CODE)
end

function netman:sendCoord(entity)
  local data = {type=self.SEND_COORD, id=entity:getId(),
                coord=entity:getCoord()}
  sendChan:push(data)
end

-- client commands
function netman:connect(host, port)
  local cmd = {type=self.CMD_CONNECT, host=host, port=port}
  cmdChan:push(cmd)
end

function netman:join(id)
  local cmd = {type=self.CMD_JOIN, id=id}
  cmdChan:push(cmd)
end

function netman:leave(id)
  local cmd = {type=self.CMD_LEAVE, id=id}
  cmdChan:push(cmd)
end

-- server commands
function netman:welcome(id)
  local cmd = {type=self.CMD_WELCOME, id=id}
  cmdChan:push(cmd)
end

-- common commands
function netman:stop()
  local cmd = {type=self.CMD_STOP}
  cmdChan:push(cmd)
  logger:info("stopping networking thread: %s", netThread)
end

return netman
