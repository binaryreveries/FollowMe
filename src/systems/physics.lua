local frictionsystem = tiny.processingSystem(class "FrictionSystem")

frictionsystem.filter = tiny.RequireAll("friction")

function frictionsystem:process(e, dt)
  -- TODO: destroy existing joints, update player, create new joints
end

return frictionsystem
