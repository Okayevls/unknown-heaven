local Players = game:GetService("Players")
local originalPos

local function checkCarrying()
    if Players.LocalPlayer.Character then
        local carrying = Players.LocalPlayer.Character:FindFirstChild("Values"):FindFirstChild("Carrying")
        if carrying then
            return carrying.Value ~= nil
        end
    end
    return false
end

return {
    Name = "KickTarget",
    Desc = "Выкидывает определенного таргета на высоту спустя время он кикается если не зареспавнится",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "MaxY", Default = 55000, Min = 55000, Max = 1500000, Step = 5000 },
        { Type = "Slider", Name = "MinY", Default = 50000, Min = 50000, Max = 50000, Step = 5000 },
    },

    OnEnable = function(ctx)
        local localChar = Players.LocalPlayer.Character
        if not localChar then return end

        local rootLocal = localChar:FindFirstChild("HumanoidRootPart")
        if not rootLocal then return end

        originalPos = rootLocal.Position.Y

        local targetHeight = math.random(ctx:GetSetting("MinY"), ctx:GetSetting("MaxY"))
        rootLocal.CFrame = CFrame.new(Vector3.new(rootLocal.Position.X, targetHeight, rootLocal.Position.Z))

        wait(0.5)
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Carry"):FireServer(false)
        Players.LocalPlayer.Character.Values.Carrying.Value = nil
        wait(0.5)

        if not checkCarrying() then
            rootLocal.CFrame = CFrame.new(Vector3.new(rootLocal.Position.X, originalPos, rootLocal.Position.Z))
            ctx:SetEnabled(false)
        end
    end,

    OnDisable = function(ctx)
    end,
}