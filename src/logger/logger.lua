local ctx = require("gamectx.global")
local serpent = require("serpent.serpent")

local logger = {}

-- levels
local FATAL = 1
local ERROR = 2
local WARN = 3
local INFO = 4
local DEBUG = 5

local function prefix(level)
  if level == FATAL then
    return "FATAL "
  elseif level == ERROR then
    return "ERROR "
  elseif level == WARN then
    return "WARN "
  elseif level == INFO then
    return "INFO "
  elseif level == DEBUG then
    return "DEBUG "
  end
  return ""
end

local function prettyPrintArgs(...)
  local args = {...}
  for i, arg in pairs(args) do
    if type(arg) == 'table' then
      args[i] = serpent.line(arg, {comment=false})
    end
  end
  return unpack(args)
end

local function logAt(level, fmt, ...)
  if level >= DEBUG and not ctx:get('debugEnabled') then
    return
  end
  local func = level == FATAL and error or print
  local msg = prefix(level) .. string.format(fmt, prettyPrintArgs(...))
  func(msg)
end

function logger:fatal(fmt, ...)
  logAt(FATAL, fmt, ...)
end

function logger:error(fmt, ...)
  logAt(ERROR, fmt, ...)
end

function logger:warn(fmt, ...)
  logAt(WARN, fmt, ...)
end

function logger:info(fmt, ...)
  logAt(INFO, fmt, ...)
end

function logger:debug(fmt, ...)
  logAt(DEBUG, fmt, ...)
end

return logger
