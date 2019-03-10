require("love.event")
require("love.timer")
local ctx = require("gamectx.global")
local logger = require("logger.logger")
local netman = require("net.netman")
local proto = require("net.proto")
local enet = require("enet")

local thread, cmdChan, sendChan = ...
local TICK_INTERVAL_MS = 1000 / ctx.NET_TICKS_S

local server = nil
local bindAttempts = 0
while not server do
  server = enet.host_create("*:" .. ctx.DEFAULT_PORT)
  bindAttempts = bindAttempts + 1
  if server then
    logger:info("bound host address *:%d after %d attempt%s", ctx.DEFAULT_PORT,
                bindAttempts, bindAttempts == 1 and "" or "s")
  elseif bindAttempts < ctx.NET_BIND_RETRY_COUNT + 1 then
    local retryCount = ctx.NET_BIND_RETRY_COUNT - bindAttempts + 1
    logger:warn("could not bind host address *:%d; retrying in %d second%s " ..
                "(%d more time%s)...", ctx.DEFAULT_PORT,
                ctx.NET_BIND_RETRY_INTERVAL_S,
                ctx.NET_BIND_RETRY_INTERVAL_S == 1 and "" or "s", retryCount,
                retryCount == 1 and "" or "s")
  else
    logger:error("failed to bind host address *:%s; giving up",
                 ctx.DEFAULT_PORT)
    goto exit
  end
  love.timer.sleep(ctx.NET_BIND_RETRY_INTERVAL_S)
end

while true do
  local cmd = cmdChan:pop()
  while cmd do
    if cmd.type == netman.CMD_WELCOME then
      proto:welcome(cmd.id, cmd.coordsById, cmd.segmentsData)
    elseif cmd.type == netman.CMD_ANNOUNCE_PLAYER_JOINED then
      proto:announcePlayerJoined(cmd.id, cmd.coord)
    elseif cmd.type == netman.CMD_ANNOUNCE_PLAYER_LEFT then
      proto:announcePlayerLeft(cmd.id)
    elseif cmd.type == netman.CMD_ANNOUNCE_PLAYER_SPRITE then
      proto:announcePlayerSprite(cmd.id, cmd.sprite)
    elseif cmd.type == netman.CMD_SEND_PLAYER_SPRITE then
      proto:sendPlayerSprite(cmd.id, cmd.sprite)
    elseif cmd.type == netman.CMD_ANNOUNCE_SHUTDOWN then
      proto:announceShutdown()
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

  proto:broadcast(server)

  -- send/recv
  local startTimeMs = love.timer.getTime() * 1000
  local event = server:service(TICK_INTERVAL_MS)
  while event do
    if event.type == 'connect' then
      logger:info("%s connected", event.peer)
      event.peer:timeout(0, 0, ctx.NET_TIMEOUT_S * 1000)
    elseif event.type == 'receive' then
      proto:recv(event.peer, event.data)
    elseif event.type == 'disconnect' then
      local client = event.peer
      logger:info("client %s disconnected", client)
      proto:clientDisconnected(client)
    end
    event = server:service()
  end

  -- slow down if we need to
  local timeDiffMs = love.timer.getTime() * 1000 - startTimeMs
  if timeDiffMs < TICK_INTERVAL_MS then
    love.timer.sleep((TICK_INTERVAL_MS - timeDiffMs) / 1000)
  end
end

::exit::
logger:info("server networking thread exiting: %s", thread)
