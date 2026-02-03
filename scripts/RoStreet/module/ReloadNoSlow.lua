local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function blockReload(actionName, inputState, inputObject)
    return Enum.ContextActionResult.Sink
end

local SupportedWeapons = {
    ["AW1"] = true, ["Ak"] = true, ["Barrett"] = true, ["Deagle"] = true, ["Double Barrel"] = true, ["Draco"] = true,
    ["Glock"] = true, ["Heli"] = true, ["M249"] = true, ["M37"] = true, ["M4"] = true, ["Micro Uzi"] = true,
    ["Rpg"] = true, ["Silencer"] = true, ["Spas"] = true, ["Taser"] = true, ["Tec"] = true, ["Ump"] = true
}

local function getEquippedWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end

    for name, _ in pairs(SupportedWeapons) do
        if char:FindFirstChild(name) and char[name]:FindFirstChild("Communication") then
            return char[name]
        end
    end

    return nil
end

local _connectionInputBegan = nil

return {
    Name = "ReloadNoSlow",
    Desc = "Нету замедления от перезарядки",
    Class = "Player",
    Category = "Utility",

    Settings = {},

    OnEnable = function(ctx)
        ContextActionService:BindAction("BlockReload", blockReload, false, Enum.KeyCode.R)
        _connectionInputBegan = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.R then
                local weapon = getEquippedWeapon()
                if weapon and weapon:FindFirstChild("Reload") then
                    weapon.Reload:InvokeServer()
                end
            end
        end)
    end,

    OnDisable = function(ctx)
        ContextActionService:UnbindAction("BlockReload")
        if _connectionInputBegan then  _connectionInputBegan:Disconnect()  _connectionInputBegan = nil  end
    end,
}