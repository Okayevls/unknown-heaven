local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local _connection = nil

return {
    Name = "Speed",
    Desc = "Дает ускорение передвижения игрока",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "MultiplierXZ", Default = 145, Min = 0, Max = 300, Step = 1 },
        { Type = "Slider", Name = "MultiplierY", Default = 0.9, Min = 0, Max = 1, Step = 0.05 },
    },

    OnEnable = function(ctx)
        _connection = RunService.Heartbeat:Connect(function()
            local currentHrp = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
            local dir = humanoid.MoveDirection
            local powerXZ = ctx:GetSetting("MultiplierXZ")
            local powerY = ctx:GetSetting("MultiplierY")
            if dir.Magnitude > 0 then
                currentHrp.Velocity = Vector3.new(dir.X * powerXZ, currentHrp.Velocity.Y * powerY, dir.Z * powerXZ)
            end
        end)
    end,

    OnDisable = function(ctx)
        _connection:Disconnect()
        _connection = nil
    end,
}