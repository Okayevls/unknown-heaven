local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local settingsConnection = nil
local RS = game:GetService("ReplicatedStorage")
local _connectionRenderStepped = nil

local _originalWeaponSettings = {}
local _originalGCConfigs = {}
local _originalReloadFuncs = {}

local function safeClear(t)
    if type(table.clear) == "function" then
        table.clear(t)
    else
        for k in pairs(t) do t[k] = nil end
    end
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
    Name = "Reload",
    Desc = "Нету замедления от перезарядки",
    Class = "Combat",
    Category = "Combat",
    Settings = {
        { Type = "Boolean", Name = "No Slow Reload", Default = false },
        { Type = "Boolean", Name = "Fast Reload", Default = false },
        { Type = "Boolean", Name = "Auto Reload", Default = false },
        { Type = "Slider", Name = "State Reload Ammo", Default = 30, Min = 0, Max = 100, Step = 1 },
    },

    OnEnable = function(ctx)
        local settingsPath = RS:FindFirstChild("Settings", true)
        local function toggleReloadBind()
            if ctx:GetSetting("Auto Reload") then
                _connectionRenderStepped = RunService.RenderStepped:Connect(function()
                    local weapon = getEquippedWeapon()
                    if weapon then
                        local ammo = weapon:FindFirstChild("Ammo")
                        if ammo and ammo.Value < ctx:GetSetting("State Reload Ammo") and weapon:FindFirstChild("Reload") then
                            weapon.Reload:InvokeServer()
                        end
                    end
                end)
            else
                if _connectionRenderStepped then _connectionRenderStepped:Disconnect() _connectionRenderStepped = nil end
            end

            if ctx:GetSetting("Fast Reload") then
                if settingsPath then
                    local WeaponSettings = require(settingsPath)

                    for _, data in pairs(WeaponSettings) do
                        if type(data) == "table" then
                            if _originalWeaponSettings[data] == nil then
                                _originalWeaponSettings[data] = {
                                    Automatic = rawget(data, "Automatic"),
                                    ReloadTime = rawget(data, "ReloadTime"),
                                }
                            end

                            data.Automatic = true
                            data.ReloadTime = 0
                        end
                    end
                end

                for _, v in pairs(getgc(true)) do
                    if type(v) == "table" then
                        local cfg = rawget(v, "Configuration")
                        if type(cfg) == "table" then
                            if _originalGCConfigs[cfg] == nil then
                                _originalGCConfigs[cfg] = {
                                    Automatic = rawget(cfg, "Automatic"),
                                    ReloadTime = rawget(cfg, "ReloadTime"),
                                }
                            end

                            cfg.Automatic = true
                            cfg.ReloadTime = 0
                        end

                        local fn = rawget(v, "PlayReloadAnim")
                        if type(fn) == "function" then
                            if _originalReloadFuncs[v] == nil then
                                _originalReloadFuncs[v] = fn
                            end

                            v.PlayReloadAnim = function(p)
                                if p and p.Animations and p.Animations.Reload then
                                    local anim = p.Animations.Reload
                                    anim:Play()
                                    anim:AdjustSpeed(100)
                                    anim:Stop()
                                end
                            end
                        end
                    end
                end
            else
                for data, original in pairs(_originalWeaponSettings) do
                    if type(data) == "table" then
                        data.Automatic = original.Automatic
                        data.ReloadTime = original.ReloadTime
                    end
                end
                safeClear(_originalWeaponSettings)

                for cfg, original in pairs(_originalGCConfigs) do
                    if type(cfg) == "table" then
                        cfg.Automatic = original.Automatic
                        cfg.ReloadTime = original.ReloadTime
                    end
                end
                safeClear(_originalGCConfigs)

                for tbl, originalFunc in pairs(_originalReloadFuncs) do
                    if type(tbl) == "table" and type(originalFunc) == "function" then
                        tbl.PlayReloadAnim = originalFunc
                    end
                end
                safeClear(_originalReloadFuncs)
            end

            if ctx:GetSetting("No Slow Reload") then
                ContextActionService:BindAction("BlockReload", handleReloadAction, false, Enum.KeyCode.R)
            else
                ContextActionService:UnbindAction("BlockReload")
            end
        end

        toggleReloadBind()

        settingsConnection = ctx.Changed:Connect(function(payload)
            if payload.moduleName == ctx.Name and payload.kind == "Setting" then
                if payload.key == "No Slow Reload" then toggleReloadBind() end
                if payload.key == "Fast Reload" then toggleReloadBind() end
            end
        end)
    end,

    OnDisable = function(ctx)
        if _connectionRenderStepped then _connectionRenderStepped:Disconnect() _connectionRenderStepped = nil end
        ContextActionService:UnbindAction("BlockReload")

        if settingsConnection then
            settingsConnection:Disconnect()
            settingsConnection = nil
        end

        for data, original in pairs(_originalWeaponSettings) do
            if type(data) == "table" then
                data.Automatic = original.Automatic
                data.ReloadTime = original.ReloadTime
            end
        end
        safeClear(_originalWeaponSettings)

        for cfg, original in pairs(_originalGCConfigs) do
            if type(cfg) == "table" then
                cfg.Automatic = original.Automatic
                cfg.ReloadTime = original.ReloadTime
            end
        end
        safeClear(_originalGCConfigs)

        for tbl, originalFunc in pairs(_originalReloadFuncs) do
            if type(tbl) == "table" and type(originalFunc) == "function" then
                tbl.PlayReloadAnim = originalFunc
            end
        end
        safeClear(_originalReloadFuncs)
    end,
}