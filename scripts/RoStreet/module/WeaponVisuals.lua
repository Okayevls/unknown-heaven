local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local _rotationConnection = nil
local _currentAngle = 0

local originalC0 = nil
local lastMotor = nil

local function updateWeaponRotation(ctx)
    if _rotationConnection then
        _rotationConnection:Disconnect()
        _rotationConnection = nil
    end

    _rotationConnection = RunService.RenderStepped:Connect(function(dt)
        local character = LocalPlayer.Character
        if not character then return end

        local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
        local motor = rightArm and rightArm:FindFirstChild("RightGrip")

        if motor and motor:IsA("Motor6D") then
            if lastMotor ~= motor then
                if lastMotor and originalC0 then lastMotor.C0 = originalC0 end
                originalC0 = motor.C0
                lastMotor = motor
            end

            local speed = ctx:GetSetting("Spin Speed") or 10
            _currentAngle = (_currentAngle + speed * dt) % (math.pi * 2)

            motor.C0 = originalC0 * CFrame.Angles(0, 0, _currentAngle)
        else
            lastMotor = nil
            originalC0 = nil
        end
    end)
end

return {
    Name = "WeaponVisuals",
    Desc = "Визуальные эффекты для оружия (Spin)",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Slider", Name = "Spin Speed", Default = 10, Min = 1, Max = 100, Step = 1},
    },

    OnEnable = function(ctx)
        updateWeaponRotation(ctx)
    end,

    OnDisable = function(ctx)
        if _rotationConnection then
            _rotationConnection:Disconnect()
            _rotationConnection = nil
        end

        if lastMotor and originalC0 then
            lastMotor.C0 = originalC0
        end
        lastMotor = nil
        originalC0 = nil
    end,
}