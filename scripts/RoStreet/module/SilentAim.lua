local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Name = "SilentAim",
    Desc = "Автоматическая стрельба и помощь в наведении",
    Class = "Combat",
    Category = "Combat",

    Settings = {
        { Type = "Boolean", Name = "Auto Stomp", Default = false },
        { Type = "Boolean", Name = "Anti Buy", Default = false },
        { Type = "Boolean", Name = "Wallbang Beta", Default = false },
    },


    OnEnable = function(self, ctx)

    end,

    OnDisable = function(self, ctx)

    end,
}