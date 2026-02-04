local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local _rotationConnection = nil
local _currentAngle = 0
local _originalC0 = nil
local _lastMotor = nil

local SupportedWeapons = {
    ["AW1"] = true, ["Ak"] = true, ["Barrett"] = true, ["Deagle"] = true, ["Double Barrel"] = true, ["Draco"] = true,
    ["Glock"] = true, ["Heli"] = true, ["M249"] = true, ["M37"] = true, ["M4"] = true, ["Micro Uzi"] = true,
    ["Rpg"] = true, ["Silencer"] = true, ["Spas"] = true, ["Taser"] = true, ["Tec"] = true, ["Ump"] = true
}

local function getEquippedWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end

    for name, _ in pairs(SupportedWeapons) do
        local tool = char:FindFirstChild(name)
        if tool and (tool:FindFirstChild("Communication") or tool:FindFirstChild("Handle")) then
            return tool
        end
    end
    return nil
end

local function updateWeaponRotation(ctx)
    if _rotationConnection then
        _rotationConnection:Disconnect()
        _rotationConnection = nil
    end

    _rotationConnection = RunService.RenderStepped:Connect(function(dt)
        local char = LocalPlayer.Character
        if not char then return end

        -- Ищем соединение оружия с рукой (Motor6D)
        local rArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        local motor = rArm and rArm:FindFirstChild("RightGrip")

        if motor and motor:IsA("Motor6D") then
            -- Сохраняем оригинал, если сменили пушку
            if _lastMotor ~= motor then
                if _lastMotor and _originalC0 then _lastMotor.C0 = _originalC0 end
                _originalC0 = motor.C0
                _lastMotor = motor
            end

            local speed = ctx:GetSetting("Spin Speed") or 10
            _currentAngle = (_currentAngle + speed * dt) % (math.pi * 2)

            -- Крутим всё вместе на 360 градусов по оси Z (можно сменить на X или Y)
            -- Умножение на originalC0 сохраняет правильную позицию пушки в ладони
            motor.C0 = _originalC0 * CFrame.Angles(0, 0, _currentAngle)
        else
            -- Если пушки нет в руках, сбрасываем кэш
            _lastMotor = nil
            _originalC0 = nil
        end
    end)
end

return {
    Name = "WeaponVisuals",
    Desc = "Вращение оружия на 360 (Spin)",
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

        -- Возвращаем пушку в нормальное положение
        if _lastMotor and _originalC0 then
            _lastMotor.C0 = _originalC0
        end
        _lastMotor = nil
        _originalC0 = nil
    end,
}