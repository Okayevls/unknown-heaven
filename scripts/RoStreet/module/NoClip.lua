local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local _connectionStepped = nil
local character
local originalCollisions = {}
local _connection = nil

local function SetCharacter(char)
    character = char
    originalCollisions = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
        end
    end
end

return {
    Name = "NoClip",
    Desc = "Позволяет проходить сквозь стены",
    Class = "Movement",
    Category = "Movement",

    Settings = {},

    OnEnable = function(ctx)
        SetCharacter(player.Character or player.CharacterAdded:Wait())
        _connection = player.CharacterAdded:Connect(SetCharacter)
        if _connectionStepped then return end

        _connectionStepped = RunService.Stepped:Connect(function()
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end,

    OnDisable = function(ctx)
        if _connectionStepped then _connectionStepped:Disconnect() _connectionStepped = nil end

        for part, canCollide in pairs(originalCollisions) do
            if part and part:IsA("BasePart") then
                part.CanCollide = canCollide
            end
        end
    end,
}