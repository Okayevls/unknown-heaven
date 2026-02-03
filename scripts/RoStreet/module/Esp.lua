local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

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

    _espData = {},
    _connections = {},
    _folder = nil,

    _updateOriginalNames = function(self, ctx)
        local hide = ctx:GetSetting("Hide Names")
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.DisplayDistanceType = hide and Enum.HumanoidDisplayDistanceType.None
                            or Enum.HumanoidDisplayDistanceType.Viewer
                end
            end
        end
    end,

    _createESP = function(self, char, plrName)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        local head = char:FindFirstChild("Head")
        if not root or not head then return nil end

        local highlight = Instance.new("Highlight")
        highlight.Name = plrName.."_ESP"
        highlight.Adornee = char
        highlight.FillTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = self._folder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = plrName.."_Info"
        billboard.Adornee = head
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.fromOffset(100, 20)
        billboard.Parent = self._folder

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.Text = plrName
        nameLabel.BorderSizePixel = 0
        nameLabel.Parent = billboard

        return {highlight = highlight, billboard = billboard, label = nameLabel, char = char}
    end,

    _clearPlayerESP = function(self, plr)
        if self._espData[plr] then
            if self._espData[plr].highlight then self._espData[plr].highlight:Destroy() end
            if self._espData[plr].billboard then self._espData[plr].billboard:Destroy() end
            self._espData[plr] = nil
        end
    end,

    OnEnable = function(self, ctx)
        if not self._folder then
            self._folder = Instance.new("Folder")
            self._folder.Name = "7A1EP"
            self._folder.Parent = CoreGui
        end

        local function setupPlayer(plr)
            if plr == Players.LocalPlayer then return end

            local function onChar(char)
                task.wait(0.5)
                self:_clearPlayerESP(plr)
                self._espData[plr] = self:_createESP(char, plr.Name)
            end

            table.insert(self._connections, plr.CharacterAdded:Connect(onChar))
            if plr.Character then onChar(plr.Character) end
        end

        for _, plr in ipairs(Players:GetPlayers()) do setupPlayer(plr) end
        table.insert(self._connections, Players.PlayerAdded:Connect(setupPlayer))

        table.insert(self._connections, Players.PlayerRemoving:Connect(function(plr)
            self:_clearPlayerESP(plr)
        end))

        table.insert(self._connections, RunService.RenderStepped:Connect(function()
            local showBox = ctx:GetSetting("Show Box")
            local showName = ctx:GetSetting("Show Name")
            local showBg = ctx:GetSetting("Show Background")
            local textSize = ctx:GetSetting("Text Size")
            local accent = ctx.Logger.prefix == "[Heaven]" and Color3.fromRGB(140, 200, 255) or Color3.new(1,1,1)

            for plr, data in pairs(self._espData) do
                if data.char and data.char.Parent then
                    data.highlight.Enabled = showBox
                    data.highlight.OutlineColor = accent

                    data.billboard.Enabled = showName
                    data.label.TextColor3 = accent
                    data.label.TextSize = textSize
                    data.label.BackgroundTransparency = showBg and 0.5 or 1
                else
                    self:_clearPlayerESP(plr)
                end
            end
        end))

        self:_updateOriginalNames(ctx)
    end,

    OnDisable = function(self, ctx)
        for _, conn in ipairs(self._connections) do conn:Disconnect() end
        self._connections = {}

        if self._folder then
            self._folder:ClearAllChildren()
        end
        self._espData = {}

        self:_updateOriginalNames(ctx)
    end,
}