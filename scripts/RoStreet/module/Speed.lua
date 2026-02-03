local Players = game:GetService("Players")
getgenv().ctx.e.new("Speed")

return {
    Name = "Speed",
    Desc = "Дает ускорение передвижения игрока",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "Multiplier", Default = 145, Min = 0, Max = 300, Step = 1 },
    },

    OnEnable = function(ctx)
        local speed = ctx:GetSetting("PowerLevel")
        function self:EUpdate()
            if not Players.LocalPlayer.Character then return end
            local currentHrp = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
            if not currentHrp or not humanoid then return end

            local dir = humanoid.MoveDirection

            if self.Enabled then
                if dir.Magnitude > 0 then
                    currentHrp.Velocity = Vector3.new(dir.X * speed.SpeedMultiplier, currentHrp.Velocity.Y * 0.9, dir.Z * speed.SpeedMultiplier)
                end
            end
        end

        event.Enable(self)
    end,

    OnDisable = function(ctx)
        event.Disable(self)
    end,
}