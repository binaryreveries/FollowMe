require("love.event")
require("love.timer")
local ctx = require("gamectx.global")
local logger = require("logger.logger")
local netman = require("net.netman")
local proto = require("net.proto")
local enet = require("enet")

local thread, cmdChan, sendChan = ...
local TICK_INTERVAL_MS = 1000 / ctx.NET_TICKS_S

local client = enet.host_create()

while true do
  local server = nil

  -- connect to a server
  local cmd = cmdChan:demand()
  if cmd.type == netman.CMD_CONNECT then
    server = proto:connect(client, cmd.host, cmd.port)
    server:timeout(0, 0, ctx.NET_TIMEOUT_S * 1000)
  elseif cmd.type == netman.CMD_JOIN then
    logger:error("must connect before attepting to join")
  elseif cmd.type == netman.CMD_LEAVE then
    logger:error("cannot leave when not connected")
  elseif cmd.type == netman.CMD_STOP then
    goto exit
  else
    logger:error("invalid command: %d", cmd.type)
  end

  if not server then
    -- nowhere to send these
    sendChan:clear()
  end

  while server do
    local cmd = cmdChan:pop()
    while cmd do
      if cmd.type == netman.CMD_JOIN then
        proto:join(server, cmd.id)
      elseif cmd.type == netman.CMD_LEAVE then
        proto:leave(server, cmd.id)
      elseif cmd.type == netman.CMD_STOP then
        goto exit
      else
        logger:error("invalid command: %d", cmd.type)
      end
      cmd = cmdChan:pop()
    end

    local data = sendChan:pop()
    while data do
      proto:prepare(server, data)
      data = sendChan:pop()
    end

    proto:send(server)

    -- send/recv
    local startTimeMs = love.timer.getTime() * 1000
    local event = client:service(TICK_INTERVAL_MS)
    while event do
      if event.type == 'connect' then
        local rc = event.data
        logger:info("%s connected", event.peer)
        love.event.push('netmanConnected', rc)
      elseif event.type == 'receive' then
        proto:recv(event.peer, event.data)
      elseif event.type == 'disconnect' then
        local rc = event.data
        if rc == netman.DISCONNECT_BAD_VERSION then
          logger:error("client/server version mismatch")
        elseif rc == netman.DISCONNECT_LEFT then
          logger:info("left server")
        end
        logger:info("%s disconnected", event.peer)
        proto:serverDisconnected(server, rc)
        love.event.push('netmanDisconnected', rc)
        server = nil
      end
      event = client:service()
    end

    -- slow down if we need to
    local timeDiffMs = love.timer.getTime() * 1000 - startTimeMs
    if timeDiffMs < TICK_INTERVAL_MS then
      love.timer.sleep((TICK_INTERVAL_MS - timeDiffMs) / 1000)
    end
  end
end

::exit::
logger:info("client networking thread exiting: %s", thread)
