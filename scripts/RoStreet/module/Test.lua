local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local connection

return {
    Name = "FlyUp",
    Desc = "Плавно поднимает игрока вверх, пока включен.",
    Class = "Movement",
    Category = "Utility",

    Settings = {
        {Type="Slider", Name="Speed", Default=5, Min=1, Max=50, Step=1},
    },

    OnEnable = function(ctx)
        local player = Players.LocalPlayer

        connection = RunService.Heartbeat:Connect(function(dt)
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                local speed = ctx:GetSetting("Speed")
                hrp.CFrame = hrp.CFrame + Vector3.new(0, speed * dt, 0)
            end
        end)

        print("[FlyUp] Enabled")
    end,

    OnDisable = function(ctx)
        if connection then
            connection:Disconnect()
            connection = nil
        end
        print("[FlyUp] Disabled")
    end,
}