return {
    Utility = {
        {
            Name = "Test",
            Desc = "Тестовый модуль: печатает в output.",
            Class = "Debug",

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

                local text = tostring(ctx:GetSetting("Text"))
                local times = tonumber(ctx:GetSetting("Times")) or 1
                local mode = tostring(ctx:GetSetting("Mode"))()

                for i = 1, times do
                    if mode == "Warn" then
                        warn("[Test] " .. text .. " #" .. i)
                    else
                        print("[Test] " .. text .. " #" .. i)
                    end
                end
            end,

            OnDisable = function(_ctx)
                print("[Test] Disabled")
            end,
        },
    },
}
