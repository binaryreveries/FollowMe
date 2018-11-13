local pavesystem = tiny.processingSystem(class "PaveSystem")

pavesystem.filter = tiny.RequireAll("pave")

function pavesystem:process(e, dt)
  -- TODO: 
end

return pavesystem
