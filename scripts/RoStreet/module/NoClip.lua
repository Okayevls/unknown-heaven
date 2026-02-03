local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

return {
    Name = "NoClip",
    Desc = "Позволяет проходить сквозь стены",
    Class = "Movement",
    Category = "Movement",

    Settings = {},

    _connection = nil,
    _originalCollisions = {},

    _setupCharacter = function(self, character)
        self._originalCollisions = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                self._originalCollisions[part] = part.CanCollide
            end
        end
    end,

    OnEnable = function(self, ctx)
        local player = Players.LocalPlayer

        if player.Character then
            self:_setupCharacter(player.Character)
        end

        self._connection = RunService.Stepped:Connect(function()
            local character = player.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end,

    OnDisable = function(self, ctx)
        if self._connection then
            self._connection:Disconnect()
            self._connection = nil
        end

        for part, wasCollidable in pairs(self._originalCollisions) do
            if part and part.Parent then
                part.CanCollide = wasCollidable
            end
        end

        self._originalCollisions = {}
    end,
}