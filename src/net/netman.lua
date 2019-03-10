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
netman.CMD_ANNOUNCE_PLAYER_JOINED = 5
netman.CMD_ANNOUNCE_PLAYER_LEFT = 6
netman.CMD_ANNOUNCE_PLAYER_SPRITE = 7
netman.CMD_SEND_PLAYER_SPRITE = 8
netman.CMD_ANNOUNCE_SHUTDOWN = 9
netman.CMD_STOP = 10

-- types of data we can request to send
netman.SEND_COORD = 1
netman.SEND_ROAD = 2

-- disconnect reasons
netman.DISCONNECT_LEFT = 0
netman.DISCONNECT_BAD_VERSION = 1

-- named channel names
netman.CHAN_RECV_SEGMENTS = 'recvSegmentsDataChan'

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

function netman:sendRoadData(segmentsData)
  if not segmentsData then
    return
  end
  local data = {type=self.SEND_ROAD, segmentsData=segmentsData}
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

function netman:sendPlayerSprite(id, sprite)
  local cmd = {type=self.CMD_SEND_PLAYER_SPRITE, id=id, sprite=sprite}
  cmdChan:push(cmd)
end

function netman:recvRoadData()
  local chan = love.thread.getChannel(self.CHAN_RECV_SEGMENTS)
  local segmentsData = chan:pop()
  if not segmentsData then
    return
  end

  -- drain all segments we've received so far
  local nextSegmentsData = chan:pop()
  while nextSegmentsData do
    for _, s in ipairs(nextSegmentsData) do
      table.insert(segmentsData, s)
    end
    nextSegmentsData = chan:pop()
  end

  -- the frontier is the most recent segment
  return segmentsData[#segmentsData], segmentsData
end

-- server commands
function netman:welcome(id, coordsById, segmentsData)
  local cmd = {type=self.CMD_WELCOME, id=id, coordsById=coordsById,
               segmentsData=segmentsData}
  cmdChan:push(cmd)
end

function netman:announcePlayerJoined(id, coord)
  local cmd = {type=self.CMD_ANNOUNCE_PLAYER_JOINED, id=id, coord=coord}
  cmdChan:push(cmd)
end

function netman:announcePlayerLeft(id)
  local cmd = {type=self.CMD_ANNOUNCE_PLAYER_LEFT, id=id}
  cmdChan:push(cmd)
end

function netman:announcePlayerSprite(id, sprite)
  local cmd = {type=self.CMD_ANNOUNCE_PLAYER_SPRITE, id=id, sprite=sprite}
  cmdChan:push(cmd)
end

function netman:announceShutdown()
  local cmd = {type=self.CMD_ANNOUNCE_SHUTDOWN}
  cmdChan:push(cmd)
end

-- common commands
function netman:stop()
  local cmd = {type=self.CMD_STOP}
  cmdChan:push(cmd)
  logger:info("stopping networking thread: %s", netThread)
end

return netman
