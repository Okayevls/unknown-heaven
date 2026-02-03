local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local EventManager = {}
EventManager.__index = EventManager

function EventManager.new(name)
    local self = setmetatable({
        Name = name,
        Connections = {},
        Enabled = false
    }, EventManager)
    return self
end

function EventManager:Enable(moduleTable)
    if self.Enabled then return end
    self.Enabled = true

    if moduleTable.EUpdate then
        table.insert(self.Connections, RunService.Heartbeat:Connect(function(dt)
            moduleTable.EUpdate(moduleTable)
        end))
    end

    if moduleTable.ERender then
        table.insert(self.Connections, RunService.RenderStepped:Connect(function(dt)
            moduleTable.ERender(moduleTable, dt)
        end))
    end

    if moduleTable.EKeyInput then
        table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gp)
            moduleTable.EKeyInput(moduleTable, input, gp)
        end))
    end
end

function EventManager:Disable()
    self.Enabled = false
    for _, conn in ipairs(self.Connections) do
        if conn.Disconnect then conn:Disconnect() end
    end
    self.Connections = {}
end

return EventManager