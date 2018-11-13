local updatesystem = tiny.processingSystem(class "UpdateSystem")

updatesystem.filter = tiny.RequireAll("update")

function updatesystem:process(e, dt)
  e:update(dt)
end

return updatesystem
