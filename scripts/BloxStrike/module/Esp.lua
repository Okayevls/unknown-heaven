local Players = game:GetService("Players")
local player = Players.LocalPlayer

local charactersFolder = workspace:WaitForChild("Characters")

local visuals = {}
local activeConnections = {}
local isEnabled = false

local function getMyTeam()
    return player:GetAttribute("Team")
end

local function removeVisuals(model)
    if visuals[model] then
        for _, v in ipairs(visuals[model]) do
            if typeof(v) == "Instance" then v:Destroy() end
        end
        visuals[model] = nil
    end
end

local function addVisuals(model)
    if not isEnabled or visuals[model] or not model:IsA("Model") then return end

    local humanoid = model:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    local head = model:WaitForChild("Head", 5)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 60, 60)
    highlight.Adornee = model
    highlight.Parent = model

    local elements = {highlight}

    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Name"
        billboard.Size = UDim2.fromOffset(100, 20)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = model.Name
        label.TextColor3 = Color3.fromRGB(255, 80, 80)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Parent = billboard

        table.insert(elements, billboard)
    end

    visuals[model] = elements

    local deathConn; deathConn = humanoid.Died:Connect(function()
        removeVisuals(model)
        deathConn:Disconnect()
    end)
end

local function processTeamFolder(folder)
    local myTeam = getMyTeam()
    if folder.Name == "Hostages" or folder.Name == myTeam then return end

    table.insert(activeConnections, folder.ChildAdded:Connect(function(child)
        task.delay(0.1, function()
            addVisuals(child)
        end)
    end))

    table.insert(activeConnections, folder.ChildRemoved:Connect(removeVisuals))

    for _, model in ipairs(folder:GetChildren()) do
        task.spawn(addVisuals, model)
    end
end

return {
    Name = "ESP",
    Desc = "Подсветка вражеских игроков",
    Class = "Visuals",
    Category = "Visuals",
    Settings = {},

    OnEnable = function(ctx)
        isEnabled = true

        local function refresh()
            for _, folder in ipairs(charactersFolder:GetChildren()) do
                if folder:IsA("Folder") then
                    processTeamFolder(folder)
                end
            end
        end

        table.insert(activeConnections, charactersFolder.ChildAdded:Connect(function(child)
            if child:IsA("Folder") then processTeamFolder(child) end
        end))

        refresh()
    end,

    OnDisable = function(ctx)
        isEnabled = false

        for _, conn in ipairs(activeConnections) do
            conn:Disconnect()
        end
        activeConnections = {}

        for model, _ in pairs(visuals) do
            removeVisuals(model)
        end
    end,
}