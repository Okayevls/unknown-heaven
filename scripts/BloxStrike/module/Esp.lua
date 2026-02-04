local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function waitForTeam()
    while not player:GetAttribute("Team") do
        player:GetAttributeChangedSignal("Team"):Wait()
    end
    return player:GetAttribute("Team")
end

local myTeam = waitForTeam()
local charactersFolder = workspace:WaitForChild("Characters")

local visuals = {}
local activeConnections = {}
local isEnabled = false

local function removeVisuals(model)
    if visuals[model] then
        for _, v in ipairs(visuals[model]) do
            if v and v.Parent then v:Destroy() end
        end
        visuals[model] = nil
    end
end

local function addVisuals(model)
    if not isEnabled then return end
    if visuals[model] or not model:IsA("Model") then return end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "EnemyHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 60, 60)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = model

    local head = model:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "EnemyName"
        billboard.Size = UDim2.fromOffset(100, 20)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = model.Name
        label.TextColor3 = Color3.fromRGB(255, 80, 80)
        label.TextStrokeTransparency = 0.5
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.Parent = billboard

        visuals[model] = {highlight, billboard}
    else
        visuals[model] = {highlight}
    end

    local dConn; dConn = humanoid.Died:Connect(function()
        removeVisuals(model)
        dConn:Disconnect()
    end)
end

local function processTeamFolder(folder)
    if folder.Name == "Hostages" or folder.Name == myTeam then return end

    for _, model in ipairs(folder:GetChildren()) do
        addVisuals(model)
    end

    table.insert(activeConnections, folder.ChildAdded:Connect(addVisuals))
    table.insert(activeConnections, folder.ChildRemoved:Connect(removeVisuals))
end

return {
    Name = "ESP",
    Desc = "Подсветка вражеских игроков",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {

    },

    OnEnable = function(ctx)
        isEnabled = true

        for _, folder in ipairs(charactersFolder:GetChildren()) do
            if folder:IsA("Folder") then
                processTeamFolder(folder)
            end
        end

        table.insert(activeConnections, charactersFolder.ChildAdded:Connect(function(child)
            if child:IsA("Folder") then
                processTeamFolder(child)
            end
        end))
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