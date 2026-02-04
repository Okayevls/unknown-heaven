local RS = game:GetService("ReplicatedStorage")

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

return {
    Name = "FastReload",
    Desc = "Быстрая перезарядка оружия",
    Class = "Player",
    Category = "Utility",

    Settings = {},

    OnEnable = function(ctx)
        local settingsPath = RS:FindFirstChild("Settings", true)
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
    end,

    OnDisable = function(ctx)
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