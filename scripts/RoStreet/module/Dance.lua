local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local currentDanceTrack = nil
local originalWalkAnimId = nil

local r6_dances = {
    ["Dance 1"] = "27789359",
    ["Dance 2"] = "30196114",
    ["Dance 3"] = "248263260",
    ["Robot"] = "45834924",
    ["Bunny"] = "33796059",
    ["Wave"] = "28488254",
    ["Laugh"] = "52155728"
}

local r15_dances = {
    ["Dance 1"] = "3333432454",
    ["Dance 2"] = "4555808220",
    ["Dance 3"] = "4049037604",
    ["Tilt"] = "4555782893",
    ["Joy"] = "10214311282",
    ["Hyped"] = "10714010337",
    ["Old School"] = "10713981723",
    ["Monkey"] = "10714372526",
    ["Shuffle"] = "10714076981",
    ["Line"] = "10714392151",
    ["Pop"] = "11444443576"
}

local function isR15(player)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        return character.Humanoid.RigType == Enum.HumanoidRigType.R15
    end
    return false
end

local function toggleWalkAnim(state)
    local char = LocalPlayer.Character
    local animateScript = char and char:FindFirstChild("Animate")
    if animateScript then
        animateScript.Enabled = state
    end
end

return {
    Name = "Dance",
    Desc = "Танцульки всякие",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        {
            Type = "ModeSetting",
            Name = "Style",
            Default = "Dance 1",
            Options = {"Dance 1", "Dance 2", "Dance 3", "Robot", "Bunny", "Wave", "Laugh", "Tilt", "Joy", "Hyped", "Old School", "Monkey", "Shuffle", "Line", "Pop"}
        },
        { Type = "Boolean", Name = "Disable Walk Anim", Default = false },
    },

    OnEnable = function(ctx)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

        if humanoid then
            local selectedStyle = ctx:GetSetting("Style")
            local animationId = isR15(LocalPlayer) and (r15_dances[selectedStyle] or r15_dances["Dance 1"]) or (r6_dances[selectedStyle] or r6_dances["Dance 1"])

            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. animationId

            currentDanceTrack = humanoid:LoadAnimation(animation)
            currentDanceTrack.Looped = true
            currentDanceTrack:Play()

            if ctx:GetSetting("Disable Walk Anim") then
                toggleWalkAnim(false)
            end
        end
    end,

    OnDisable = function(ctx)
        toggleWalkAnim(true)

        if currentDanceTrack then
            currentDanceTrack:Stop()
            currentDanceTrack:Destroy()
            currentDanceTrack = nil
        end
    end,
}