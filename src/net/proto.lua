require("love.event")
local logger = require("logger.logger")
local netman = require("net.netman")
local serpent = require("serpent.serpent")

local proto = {}

-- increment the version whenever the proto changes
local VERSION = 3

-- types of commands
local PROTOCMD_JOIN = 1 -- join the server
local PROTOCMD_LEAVE = 2 -- leave the server
local PROTOCMD_WELCOME = 3 -- welcome the client into the server
local PROTOCMD_REJECT = 4 -- disallow the client from joining the server
local PROTOCMD_ANNOUNCE_PLAYER_JOINED = 5 -- a new player appeared
local PROTOCMD_ANNOUNCE_PLAYER_LEFT = 6 -- a player has left
local PROTOCMD_SEND = 7 -- a payload of data

-- keep track of client peers by player id
local clientsById = {}

-- keep track of which peers we are joined with
local joinedPeers = {}

-- buffers of outgoing data to peers
local sendDataByPeer = {}

local function allocSendData()
  -- the schema of data sent to a peer
  local data = {
    cmd=PROTOCMD_SEND,
    coordsById={},
    segmentsData={},
  }
  return data
end

local function getSendData(peer)
  -- XXX JCD peer can also be an enet.host for building up broadcasts
  local data = sendDataByPeer[peer]
  if not data then
    data = allocSendData()
    sendDataByPeer[peer] = data
  end
  return data
end

local function clearSendData(peer)
  sendDataByPeer[peer] = nil
end

local function msgFromData(data)
  return serpent.dump(data)
end

local function dataFromMsg(msg)
  local ok, data = serpent.load(msg)
  if not ok then
    logger:error("failed to decode message: %s", msg)
    return nil
  end
  -- TODO validate schema of data
  return data
end

function proto:connect(client, host, port)
  local serverAddr = string.format("%s:%u", host, port)
  return client:connect(serverAddr)
end

function proto:join(server, id)
  local data = {cmd=PROTOCMD_JOIN, version=VERSION, id=id}
  local msg = msgFromData(data)
  server:send(msg)
end

function proto:leave(server, id)
  local data = {cmd=PROTOCMD_LEAVE, id=id}
  local msg = msgFromData(data)
  server:send(msg)
end

function proto:clientDisconnected(peer)
  joinedPeers[peer] = nil
  for id, client in pairs(clientsById) do
    if client == peer then
      love.event.push('netmanPlayerLeft', id)
      clientsById[id] = nil
    end
  end
end

function proto:serverDisconnected(server)
  joinedPeers[server] = nil
end

function proto:welcome(id, coordsById, segmentsData)
  local client = clientsById[id]
  if not client then
    logger:error("could not find connection for player %s", id)
    return
  end
  joinedPeers[client] = true
  love.event.push('netmanPlayerJoined', id)
  local data = {cmd=PROTOCMD_WELCOME, id=id, coordsById=coordsById,
                segmentsData=segmentsData, text="welcome to the server!"}
  local msg = msgFromData(data)
  client:send(msg)
end

function proto:reject(peer, id, reason)
  local data = {cmd=PROTOCMD_REJECT, id=id, text=reason}
  local msg = msgFromData(data)
  peer:send(msg)
end

function proto:announcePlayerJoined(id, coord)
  local data = {cmd=PROTOCMD_ANNOUNCE_PLAYER_JOINED, id=id, coord=coord}
  local msg = msgFromData(data)
  for peer in pairs(joinedPeers) do
    peer:send(msg)
  end
end

function proto:announcePlayerLeft(id)
  local data = {cmd=PROTOCMD_ANNOUNCE_PLAYER_LEFT, id=id}
  local msg = msgFromData(data)
  for peer in pairs(joinedPeers) do
    peer:send(msg)
  end
end

function proto:prepare(peer, data)
  local sendData = getSendData(peer)
  if data.type == netman.SEND_COORD then
    -- we only care about the most recent coord; overwrite whatever is here
    sendData.coordsById[data.id] = data.coord
  elseif data.type == netman.SEND_ROAD then
    for _, s in ipairs(data.segmentsData) do
      table.insert(sendData.segmentsData, s)
    end
  else
    logger:fatal("unrecognized send request type: %s", data.type)
  end
end

function proto:send(peer)
  if not joinedPeers[peer] then
    -- we're not joined yet; don't send any data
    return
  end
  local data = getSendData(peer)
  local msg = msgFromData(data)
  peer:send(msg)
  clearSendData(peer)
end

function proto:broadcast(server)
  -- TODO JCD make it so we can broadcast more than just sendData
  local data = getSendData(server)
  local msg = msgFromData(data)
  for peer in pairs(joinedPeers) do
    peer:send(msg)
  end
  clearSendData(server)
end

function proto:recv(peer, msg)
  local data = dataFromMsg(msg)
  if not data then
    return
  end

  if data.cmd == PROTOCMD_JOIN then
    if data.version == VERSION then
      clientsById[data.id] = peer
      love.event.push('netmanPlayerJoinRequest', data.id)
    else
      logger:error("client version %u, but server running %u",
                   data.version, VERSION)
      peer:disconnect(netman.DISCONNECT_BAD_VERSION)
    end
  elseif data.cmd == PROTOCMD_LEAVE then
    love.event.push('netmanPlayerLeft', data.id)
    clientsById[data.id] = nil
    local remainingPlayersOnPeer = 0
    for _, client in pairs(clientsById) do
      if client == peer then
        remainingPlayersOnPeer = remainingPlayersOnPeer + 1
      end
    end
    if remainingPlayersOnPeer == 0 then
      joinedPeers[peer] = nil
      peer:disconnect(netman.DISCONNECT_LEFT)
    end
  elseif data.cmd == PROTOCMD_WELCOME then
    joinedPeers[peer] = true
    love.event.push('netmanJoined', data.id, data.text)
    for id, coord in pairs(data.coordsById) do
      love.event.push('netmanPlayerJoined', id, coord)
    end
    love.thread.getChannel(netman.CHAN_RECV_SEGMENTS):push(data.segmentsData)
  elseif data.cmd == PROTOCMD_REJECT then
    love.event.push('netmanRejected', data.id, data.text)
  elseif data.cmd == PROTOCMD_ANNOUNCE_PLAYER_JOINED then
    love.event.push('netmanPlayerJoined', data.id, data.coord)
  elseif data.cmd == PROTOCMD_ANNOUNCE_PLAYER_LEFT then
    love.event.push('netmanPlayerLeft', data.id)
  elseif data.cmd == PROTOCMD_SEND then
    for id, coord in pairs(data.coordsById) do
      love.event.push('netmanRecvCoord', id, coord)
    end
    love.thread.getChannel(netman.CHAN_RECV_SEGMENTS):push(data.segmentsData)
  else
    logger:error("unsupported proto cmd: %d", data.cmd)
  end
end

return proto
