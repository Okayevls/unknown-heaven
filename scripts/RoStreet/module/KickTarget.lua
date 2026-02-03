local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Name = "KickTarget",
    Desc = "Поднимает персонажа на огромную высоту для сброса цели",
    Class = "Player",
    Category = "Utility",

    Settings = {
        { Type = "Slider", Name = "MaxY", Default = 55000, Min = 50000, Max = 1500000, Step = 5000 },
        { Type = "Slider", Name = "MinY", Default = 50000, Min = 0, Max = 50000, Step = 5000 },
    },

    OnEnable = function(self, ctx)

    end,

    OnDisable = function(self, ctx)

    end,
}