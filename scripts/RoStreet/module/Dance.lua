local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local currentDanceTrack = nil
local settingsConnection = nil
local charAddedConnection = nil

local r15_dances = {
    ["Dance 1"] = "3333432454", ["Dance 2"] = "4555808220", ["Dance 3"] = "4049037604",
    ["Tilt"] = "4555782893", ["Joy"] = "10214311282", ["Hyped"] = "10714010337",
    ["Old School"] = "10713981723", ["Monkey"] = "10714372526",
    ["Shuffle"] = "10714076981", ["Line"] = "10714392151", ["Pop"] = "11444443576",
    ["Floss"] = "10714340543", ["HeyMove"] = "119734573196374", ["BillyBounce"] = "133394554631338"
}

local function toggleWalkAnim(state)
    local char = LocalPlayer.Character
    local animateScript = char and char:FindFirstChild("Animate")
    if animateScript then
        animateScript.Enabled = state
    end
end

local function refresh(ctx)
    local character = LocalPlayer.Character
    local humanoid = character and character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    if currentDanceTrack then
        currentDanceTrack:Stop()
        currentDanceTrack:Destroy()
        currentDanceTrack = nil
    end

    local selectedStyle = ctx:GetSetting("Style")
    local animationId = (r15_dances[selectedStyle] or r15_dances["Dance 1"])

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animationId

    currentDanceTrack = humanoid:LoadAnimation(animation)
    currentDanceTrack.Looped = true
    currentDanceTrack:Play()

    toggleWalkAnim(not ctx:GetSetting("Disable Walk Anim"))
end

return {
    Name = "Dance",
    Desc = "Танцульки с мгновенным откликом",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        {
            Type = "ModeSetting",
            Name = "Style",
            Default = "Dance 1",
            Options = {"Dance 1", "Dance 2", "Dance 3", "Tilt", "Joy", "Hyped", "Old School",
                       "Monkey", "Shuffle", "Line", "Pop", "Floss", "HeyMove", "BillyBounce"}
        },
        { Type = "Boolean", Name = "Disable Walk Anim", Default = false },
    },

    OnEnable = function(ctx)
        refresh(ctx)

        charAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            refresh(ctx)
        end)

        settingsConnection = ctx.Changed:Connect(function(payload)
            if payload.moduleName == ctx.Name and payload.kind == "Setting" then
                refresh(ctx)
            end
        end)
    end,

    OnDisable = function(ctx)
        if charAddedConnection then
            charAddedConnection:Disconnect()
            charAddedConnection = nil
        end

        if settingsConnection then
            settingsConnection:Disconnect()
            settingsConnection = nil
        end

        toggleWalkAnim(true)

        if currentDanceTrack then
            currentDanceTrack:Stop()
            currentDanceTrack:Destroy()
            currentDanceTrack = nil
        end
    end,
}