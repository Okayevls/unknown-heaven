local Players = game:GetService("Players")
local event = getgenv().ctx.e.new("Speed")

return {
    Name = "Speed",
    Desc = "Дает ускорение передвижения игрока",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "Multiplier", Default = 145, Min = 0, Max = 300, Step = 1 },
    },

    EUpdate = function(self)
        local char = Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")

        if hrp and humanoid then
            local speedVal = getgenv().ctx.moduleMgr:GetSetting("Movement", "Speed", "Multiplier")
            local dir = humanoid.MoveDirection

            if dir.Magnitude > 0 then
                hrp.Velocity = Vector3.new(dir.X * speedVal, hrp.Velocity.Y, dir.Z * speedVal)
            end
        end
    end,

    OnEnable = function(ctx)
        event:Enable(ctx.Module.Definition)
    end,

    OnDisable = function(ctx)
        event:Disable()
    end,
}