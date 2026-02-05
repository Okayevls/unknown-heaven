--[[
    HEAVEN ENGINE - Используй этот файл для создания новых модулей это шаблон для новых создателей
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- [ ПЕРЕМЕННЫЕ МОДУЛЯ ]
-- Храни тут соединения и временные объекты, чтобы легко чистить их в OnDisable
local connection = nil
local visualFolder = nil

return {
    -- [1. МЕТАДАННЫЕ ]
    Name = "MasterModule",           -- Название в GUI
    Desc = "Описание всех возможностей движка",  --Описание
    Class = "Player",               -- Combat, Movement, Player, Render
    Category = "Utility",            -- Внутренняя категория

    -- [2. КОНФИГУРАЦИЯ НАСТРОЕК ]
    Settings = {
        -- Переключатель
        { Type = "Boolean", Name = "ToggleOption", Default = false },

        -- Слайдер
        { Type = "Slider", Name = "PowerLevel", Default = 10, Min = 0, Max = 100, Step = 1 },

        -- Выбор режима
        { Type = "ModeSetting", Name = "Mode", Default = "Smooth", Options = {"Smooth", "Hard", "Instant"} },

        -- Текстовое поле
        { Type = "String", Name = "TargetKey", Default = "Enter name here" },

        -- Мульти-выбор (таблица чекбоксов)
        {
            Type = "MultiBoolean",
            Name = "Filters",
            Default = { ["Players"] = true, ["NPCs"] = false, ["Items"] = true }
        },
    },

    -- [3. ЛОГИКА ВКЛЮЧЕНИЯ ]
    OnEnable = function(ctx)
        -- ПОЛУЧЕНИЕ ЗНАЧЕНИЙ (Value)
        local isEnabled = ctx:GetSetting("ToggleOption")
        local speed = ctx:GetSetting("PowerLevel")
        local currentMode = ctx:GetSetting("Mode")
        local multi = ctx:GetSetting("Filters")

        -- ПОЛУЧЕНИЕ ДАННЫХ НАСТРОЙКИ (Min, Max, Options)
        -- Доступно благодаря нашему обновлению в ModuleManager!
        local powerData = ctx:GetSettingData("PowerLevel")
        if powerData then
            print("Лимиты модуля: от " .. powerData.Min .. " до " .. powerData.Max)
        end

        local modeData = ctx:GetSettingData("Mode")
        if modeData then
            print("Всего доступно режимов: " .. #modeData.Options)
        end

        -- ПРИМЕР: Создание цикла работы
        connection = RunService.Heartbeat:Connect(function(dt)
            -- Внутри цикла всегда берем свежее значение настройки
            local dynamicPower = ctx:GetSetting("PowerLevel")

            local char = Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hrp and isEnabled then
                -- Твоя магия здесь
            end
        end)

        print("[Heaven]: " .. ctx.Name .. " запущен!")
    end,

    -- [4. ЛОГИКА ВЫКЛЮЧЕНИЯ ]
    OnDisable = function(ctx)
        -- ОБЯЗАТЕЛЬНО: Отключаем циклы
        if connection then
            connection:Disconnect()
            connection = nil
        end

        -- ОБЯЗАТЕЛЬНО: Удаляем визуальные объекты (ESP, линии и т.д.)
        if visualFolder then
            visualFolder:Destroy()
            visualFolder = nil
        end

        print("[Heaven]: " .. ctx.Name .. " остановлен.")
    end,
}