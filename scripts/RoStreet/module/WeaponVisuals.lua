local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local _rotationConnection = nil
local _currentAngle = 0

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
        if tool and tool:FindFirstChild("Communication") then
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
        local weapon = getEquippedWeapon()
        if weapon and weapon:FindFirstChild("Handle") then
            local speed = ctx:GetSetting("Spin Speed") or 10
            _currentAngle = (_currentAngle + speed * dt) % (math.pi * 2)

            weapon.Grip = CFrame.Angles(0, 0, _currentAngle)
        end
    end)
end

return {
    Name = "WeaponVisuals",
    Desc = "Визуальные эффекты для оружия",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Slider", Name = "Spin Speed", Default = 10, Min = 1, Max = 50, Step = 1},
    },

    OnEnable = function(ctx)
        updateWeaponRotation(ctx)
    end,

    OnDisable = function(ctx)
        if _rotationConnection then
            _rotationConnection:Disconnect()
            _rotationConnection = nil
        end

        local weapon = getEquippedWeapon()
        if weapon then weapon.Grip = CFrame.new(0, 0, 0) end
    end,
}