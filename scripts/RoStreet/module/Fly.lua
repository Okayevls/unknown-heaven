local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

return {
    Name = "Fly",
    Desc = "Позволяет свободно летать по карте",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "Fly Speed", Default = 1.5, Min = 0.1, Max = 10, Step = 0.05 },
    },

    OnEnable = function(self, ctx)

    end,

    OnDisable = function(self, ctx)

    end,
}