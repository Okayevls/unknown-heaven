local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local currentDanceTrack = nil

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

return {
    Name = "Dance",
    Desc = "Танцульки всякие с выбором режима",
    Class = "Visual",
    Category = "Visual",

    Settings = {
        {
            Type = "ModeSetting",
            Name = "Style",
            Default = "Dance 1",
            Options = {"Dance 1", "Dance 2", "Dance 3", "Robot", "Bunny", "Wave", "Laugh", "Tilt", "Joy", "Hyped", "Old School", "Monkey", "Shuffle", "Line", "Pop"}
        },
    },

    OnEnable = function(ctx)
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

        if humanoid then
            local selectedStyle = ctx:GetSetting("Style")
            local animationId = ""

            if isR15(LocalPlayer) then
                animationId = r15_dances[selectedStyle] or r15_dances["Dance 1"]
            else
                animationId = r6_dances[selectedStyle] or r6_dances["Dance 1"]
            end

            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. animationId

            currentDanceTrack = humanoid:LoadAnimation(animation)
            currentDanceTrack.Looped = true
            currentDanceTrack:Play()
        end
    end,

    OnDisable = function(ctx)
        if currentDanceTrack then
            currentDanceTrack:Stop()
            currentDanceTrack:Destroy()
            currentDanceTrack = nil
        end
    end,
}