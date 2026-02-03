return {
    Name = "Test",
    Desc = "Тестовый модуль: печатает в output.",
    Class = "Debug",
    Category = "Utility",

    Settings = {
        {Type="Boolean", Name="DoPrint", Default=true},
        {Type="Slider",  Name="Times",   Default=3, Min=1, Max=10, Step=1},
        {Type="String",  Name="Text",    Default="Hello from Test"},
        {Type="ModeSetting", Name="Mode", Default="Print", Options={"Print","Warn"}},
    },

    OnEnable = function(ctx)
        if ctx:GetSetting("DoPrint") ~= true then
            return
        end

        local text = ctx:GetSetting("Text")
        local times = ctx:GetSetting("Times")
        local mode = ctx:GetSetting("Mode")

        for i = 1, times do
            if mode == "Warn" then
                warn("[Test] " .. tostring(text) .. " #" .. i)
            else
                print("[Test] " .. tostring(text) .. " #" .. i)
            end
        end
    end,

    OnDisable = function(ctx)
        print("[Test] Disabled")
    end,
}