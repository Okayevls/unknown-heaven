local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

local function handleReloadAction(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        local weapon = getEquippedWeapon()
        if weapon and weapon:FindFirstChild("Reload") then
            weapon.Reload:InvokeServer()
        end
    end
    return Enum.ContextActionResult.Sink
end

return {
    Name = "ReloadNoSlow",
    Desc = "Нету замедления от перезарядки",
    Class = "Player",
    Category = "Utility",
    Settings = {},

    OnEnable = function(ctx)
        ContextActionService:BindAction("BlockReload", handleReloadAction, false, Enum.KeyCode.R)
    end,

    OnDisable = function(ctx)
        ContextActionService:UnbindAction("BlockReload")
    end,
}