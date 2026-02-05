
return {
    Name = "Test",
    Desc = "Test XD",
    Class = "Test",
    Category = "Test",

    Settings = {
        { Type = "Boolean", Name = "Test8", Default = false },
        { Type = "BindSetting", Name = "Test9", Default = { kind = "KeyCode", code = Enum.KeyCode.H } },
        { Type = "ModeSetting", Name = "Test10", Default = "Test", Options = {"Test", "Test2"} },
        { Type = "Slider", Name = "Test11", Default = 0.165, Min = 0.1, Max = 0.5, Step = 0.005 },
    },

    OnEnable = function(ctx)

    end,

    OnDisable = function(ctx)

    end,
}