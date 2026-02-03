local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espFolder = Instance.new("Folder")
espFolder.Name = "StorageE4P"
espFolder.Parent = CoreGui

local espData = {}
local _connections = {}

local ESP_SETTINGS = {
    Color = Color3.fromRGB(255, 255, 255),
    MaxDistance = 2000,
}

local function updateOriginalNames(hide)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.DisplayDistanceType = hide and Enum.HumanoidDisplayDistanceType.None
                        or Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
    end
end

local function clearPlrESP(plr)
    if espData[plr] then
        for _, obj in ipairs(espData[plr]) do
            if typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
        espData[plr] = nil
    end
end

local function createESP(plr)
    local char = plr.Character
    if not char then return end

    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    local head = char:FindFirstChild("Head") or root

    local highlight = Instance.new("Highlight")
    highlight.Name = plr.Name .. "_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineColor = ESP_SETTINGS.Color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = plr.Name .. "_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(100, 25)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = ESP_SETTINGS.Color
    label.Font = Enum.Font.GothamBold
    label.Text = plr.Name
    label.BorderSizePixel = 0
    label.Parent = billboard

    espData[plr] = {highlight, billboard, char, label}
end

return {
    Name = "ESP",
    Desc = "Подсветка игроков и отображение имен через стены",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Boolean", Name = "Show Box", Default = false },
        { Type = "Boolean", Name = "Show Name", Default = false },
        { Type = "Boolean", Name = "Show Background", Default = false },
        { Type = "Boolean", Name = "Hide Original Names", Default = false },
        { Type = "Slider", Name = "Text Size", Default = 14, Min = 8, Max = 32, Step = 1 },
    },

    OnEnable = function(ctx)
        for _, plr in ipairs(Players:GetPlayers()) do
            clearPlrESP(plr)
            if plr ~= LocalPlayer then
                createESP(plr)
            end
        end

        table.insert(_connections, Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function()
                task.wait(0.5)
                createESP(plr)
            end)
        end))

        table.insert(_connections, Players.PlayerRemoving:Connect(function(plr)
            clearPlrESP(plr)
        end))

        table.insert(_connections, RunService.RenderStepped:Connect(function()
            local showBox = ctx:GetSetting("Show Box")
            local showName = ctx:GetSetting("Show Name")
            local showBg = ctx:GetSetting("Show Background")
            local hideNames = ctx:GetSetting("Hide Original Names")
            local textSize = ctx:GetSetting("Text Size")

            updateOriginalNames(hideNames)

            for plr, data in pairs(espData) do
                local highlight, billboard, char, label = data[1], data[2], data[3], data[4]

                if char and char.Parent and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    local dist = (Camera.CFrame.Position - root.Position).Magnitude

                    if dist <= ESP_SETTINGS.MaxDistance then
                        highlight.Enabled = showBox
                        highlight.OutlineTransparency = showBox and 0 or 1

                        billboard.Enabled = showName
                        label.TextSize = textSize
                        label.BackgroundTransparency = showBg and 0.5 or 1
                        label.BackgroundColor3 = Color3.new(0,0,0)

                        local scale = math.clamp(1 - (dist / 500), 0.5, 1)
                        billboard.Size = UDim2.fromOffset(100 * scale, 25 * scale)
                    else
                        highlight.Enabled = false
                        billboard.Enabled = false
                    end
                else
                    highlight.Enabled = false
                    billboard.Enabled = false
                end
            end
        end))
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(_connections) do
            conn:Disconnect()
        end
        _connections = {}

        updateOriginalNames(false)

        for plr, _ in pairs(espData) do
            clearPlrESP(plr)
        end
        espData = {}
    end,
}