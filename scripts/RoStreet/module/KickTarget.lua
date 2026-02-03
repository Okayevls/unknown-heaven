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

    _originalPos = nil,

    _checkCarrying = function()
        local char = Players.LocalPlayer.Character
        local values = char and char:FindFirstChild("Values")
        local carrying = values and values:FindFirstChild("Carrying")
        return carrying and carrying.Value ~= nil
    end,

    _performKick = function(self, ctx)
        local char = Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local minY = ctx:GetSetting("MinY")
        local maxY = ctx:GetSetting("MaxY")
        local targetHeight = math.random(math.min(minY, maxY), math.max(minY, maxY))

        root.CFrame = CFrame.new(root.Position.X, targetHeight, root.Position.Z)

        task.wait(0.5)

        local carryRemote = ReplicatedStorage:FindFirstChild("Carry", true)
        if carryRemote then
            carryRemote:FireServer(false)
        end

        if char:FindFirstChild("Values") and char.Values:FindFirstChild("Carrying") then
            char.Values.Carrying.Value = nil
        end

        task.wait(0.5)

        if not self._checkCarrying() then
            if self._originalPos then
                root.CFrame = CFrame.new(root.Position.X, self._originalPos, root.Position.Z)
            end

            ctx.moduleMgr:SetEnabled(self.Category, self.Name, false)
        else
            ctx.Logger:Warn("KickTarget: Не удалось сбросить цель.")
        end
    end,

    OnEnable = function(self, ctx)
        local char = Players.LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if not root then
            ctx.Logger:Error("KickTarget: HumanoidRootPart не найден.")
            ctx.moduleMgr:SetEnabled(self.Category, self.Name, false)
            return
        end

        self._originalPos = root.Position.Y

        task.spawn(function()
            self._performKick(self, ctx)
        end)
    end,

    OnDisable = function(self, ctx)
        self._originalPos = nil
    end,
}