local logger = {}

function logger:log(msg, ...)
  print(string.format(msg, ...))
end

function logger:log_debug(msg, ...)
  if not debug_enabled then
    return
  end
  print(string.format(msg, ...))
end

function logger:log_fatal(msg, ...)
  error(string.format(msg, ...))
end

return logger
