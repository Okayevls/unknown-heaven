local RS = game:GetService("ReplicatedStorage")

local _originalWeaponSettings = {}
local _originalGCConfigs = {}
local _originalReloadFuncs = {}

return {
    Name = "FastReload",
    Desc = "Быстрая перезарядка оружия",
    Class = "Player",
    Category = "Utility",

    Settings = {
        { Type = "Slider", Name = "MaxY", Default = 55000, Min = 50000, Max = 1500000, Step = 5000 },
        { Type = "Slider", Name = "MinY", Default = 50000, Min = 0, Max = 50000, Step = 5000 },
    },

    OnEnable = function(ctx)
        local settingsPath = RS:FindFirstChild("Settings", true)
        if settingsPath then
            local WeaponSettings = require(settingsPath)

            for weaponName, data in pairs(WeaponSettings) do
                if type(data) == "table" then
                    _originalWeaponSettings[weaponName] = {
                        Automatic = data.Automatic,
                        ReloadTime = data.ReloadTime
                    }

                    data.Automatic = true
                    data.ReloadTime = 0
                end
            end
        end

        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                if rawget(v, "Configuration") and type(v.Configuration) == "table" then
                    if not _originalGCConfigs[v] then
                        _originalGCConfigs[v] = {
                            Automatic = v.Configuration.Automatic,
                            ReloadTime = v.Configuration.ReloadTime
                        }
                    end

                    v.Configuration.Automatic = true
                    v.Configuration.ReloadTime = 0
                end

                if rawget(v, "PlayReloadAnim") and type(v.PlayReloadAnim) == "function" then
                    if not _originalReloadFuncs[v] then
                        _originalReloadFuncs[v] = v.PlayReloadAnim
                    end

                    v.PlayReloadAnim = function(p)
                        if p.Animations and p.Animations.Reload then
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
        local settingsPath = RS:FindFirstChild("Settings", true)
        if settingsPath then
            local WeaponSettings = require(settingsPath)

            for weaponName, original in pairs(_originalWeaponSettings) do
                local data = WeaponSettings[weaponName]
                if type(data) == "table" then
                    data.Automatic = original.Automatic
                    data.ReloadTime = original.ReloadTime
                end
            end
        end

        _originalWeaponSettings = {}

        for tbl, original in pairs(_originalGCConfigs) do
            if tbl and rawget(tbl, "Configuration") and type(tbl.Configuration) == "table" then
                tbl.Configuration.Automatic = original.Automatic
                tbl.Configuration.ReloadTime = original.ReloadTime
            end
        end

        _originalGCConfigs = {}

        for tbl, originalFunc in pairs(_originalReloadFuncs) do
            if tbl and rawget(tbl, "PlayReloadAnim") then
                tbl.PlayReloadAnim = originalFunc
            end
        end

        _originalReloadFuncs = {}
    end,
}