local util = require("util.util")

local tire = {}

local tireDataType = "tire"

function tire:create(x, y, maxDriveForce, maxLateralImpulse)
    -- 0.5, 1.25
    local width, height = 1, 2.5

    local t = {
        body = love.physics.newBody(world, x, y, "dynamic"),
        shape = love.physics.newRectangleShape(width, height),
        fixture = nil,
        desiredSpeed = 0,
        desiredTorque = 0,
        traction = 1,
        surfaces = {}
    }

    -- attach fixture to body and set density to 1
    t.fixture = love.physics.newFixture(t.body, t.shape, 1)
    t.fixture:setUserData({type = tireDataType})

    -- attach tire to body for use during contact callbacks
    t.body:setUserData(t)

    function t:destroy() self.body:destroy() end

    function t:draw()
        love.graphics.polygon("line",
                              self.body:getWorldPoints(self.shape:getPoints()))
    end

    function t:getForwardVelocity()
        local nx, ny = self.body:getWorldVector(0, 1)
        local lx, ly = self.body:getLinearVelocity()
        local scalar = util:dotProduct(nx, ny, lx, ly)
        return nx * scalar, ny * scalar
    end

    function t:getLateralVelocity()
        local nx, ny = self.body:getWorldVector(1, 0)
        local lx, ly = self.body:getLinearVelocity()
        local scalar = util:dotProduct(nx, ny, lx, ly)
        return nx * scalar, ny * scalar
    end

    function t:surfaceAdd(s)
        self.surfaces[s] = s
        self:updateTraction()
    end

    function t:surfaceRemove(s)
        self.surfaces[s] = nil
        self:updateTraction()
    end

    function t:update(desiredSpeed, desiredTorque)
        self:updateFriction()
        self:updateDrive(desiredSpeed)
        self:updateTurn(desiredTorque)
    end

    function t:updateDrive(desiredSpeed)
        local nx, ny = self.body:getWorldVector(0, 1)
        local fx, fy = self:getForwardVelocity()
        speed = util:dotProduct(fx, fy, nx, ny)

        local force = 0
        if desiredSpeed > speed then
            force = maxDriveForce
        elseif desiredSpeed < speed then
            force = -maxDriveForce
        else
            return
        end
        self.body:applyForce(force * nx, force * ny, self.body:getWorldCenter())
    end

    function t:updateFriction()
        -- lateral force
        local vx, vy = self:getLateralVelocity()
        local mass = self.body:getMass()
        local lx, ly = mass * -vx, mass * -vy
        local magnitude = math.sqrt(lx * lx, ly * ly)
        if magnitude > 0 then
            if magnitude > maxLateralImpulse then
                lx = lx * maxLateralImpulse / magnitude
                ly = ly * maxLateralImpulse / magnitude
            end
            self.body:applyLinearImpulse(self.traction * lx, self.traction * ly,
                                         self.body:getWorldCenter())
        end

        -- rotational force
        local afactor = 0.1
        local aimpulse = afactor * self.body:getInertia() *
                             -self.body:getAngularVelocity()
        self.body:applyAngularImpulse(self.traction * aimpulse)

        -- longitudinal force
        local nx, ny = self:getForwardVelocity()
        local speed = math.sqrt(nx * nx + ny * ny)
        if speed > 0 then
            -- normalize vector by dividing by magnitude (e.g. speed)
            nx = nx / speed
            ny = ny / speed

            local ffactor = -2
            local dragForceMagnitude = ffactor * speed
            local fx, fy = dragForceMagnitude * nx, dragForceMagnitude * ny
            self.body:applyForce(self.traction * fx, self.traction * fy,
                                 self.body:getWorldCenter())
        end
    end

    function t:updateTraction(desiredTorque)
        if next(self.surfaces) == nil then
            self.traction = 1
        else
            -- find highest traction of currently contacted surfaces
            self.traction = 0
            for _, ga in pairs(self.surfaces) do
                if ga.friction > self.traction then
                    self.traction = ga.friction
                end
            end
        end
    end

    function t:updateTurn(desiredTorque) self.body:applyTorque(desiredTorque) end

    return t
end

return tire
