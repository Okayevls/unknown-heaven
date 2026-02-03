

return {
    Name = "SilentAim",
    Desc = "Автоматическая стрельба и помощь в наведении",
    Class = "Combat",
    Category = "Combat",

    Settings = {
        { Type = "Boolean", Name = "AntiBuy", Default = false },
        { Type = "BindSetting", Name = "AutoStomp", Default = { kind = "KeyCode", code = Enum.KeyCode.N } },
    },

    OnEnable = function(self, ctx)

    end,

    OnDisable = function(self, ctx)

    end,
}