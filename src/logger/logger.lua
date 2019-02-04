local logger = {}

function logger:info(msg, ...)
  print(string.format(msg, ...))
end

function logger:debug(msg, ...)
  if not debug_enabled then
    return
  end
  print(string.format(msg, ...))
end

function logger:fatal(msg, ...)
  error(string.format(msg, ...))
end

return logger
