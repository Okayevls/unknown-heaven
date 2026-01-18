local Players = game:GetService("Players")

local RenderUtil = {}
RenderUtil.__index = RenderUtil

local function safeParent(gui)
    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if ok then return end

    local lp = Players.LocalPlayer
    if lp then
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then gui.Parent = pg; return end
    end

    gui.Parent = game:GetService("StarterGui")
end

local function mkScreenGui(name)
    local gui = Instance.new("ScreenGui")
    gui.Name = name or "RenderUtil"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    safeParent(gui)
    return gui
end

local function applyProps(inst, props)
    if not props then return end
    for k, v in pairs(props) do
        inst[k] = v
    end
end

function RenderUtil.new(opts)
    opts = opts or {}
    local self = setmetatable({}, RenderUtil)

    self.Gui = opts.Gui or mkScreenGui(opts.Name or "UiRender_Root")
    self.Root = Instance.new("Frame")
    self.Root.Name = "Root"
    self.Root.Size = UDim2.fromScale(1, 1)
    self.Root.BackgroundTransparency = 1
    self.Root.Parent = self.Gui

    self._z = opts.ZIndex or 50
    return self
end

function RenderUtil:SetEnabled(state)
    if self.Gui then self.Gui.Enabled = state and true or false end
end

function RenderUtil:Destroy()
    if self.Gui then self.Gui:Destroy() end
    self.Gui = nil
end

local function wrap(inst, extra)
    local obj = {}
    obj.Instance = inst

    function obj:Set(props)
        applyProps(inst, props)
        if extra and extra.Set then extra.Set(props) end
        return obj
    end

    function obj:Destroy()
        if inst then inst:Destroy() end
        inst = nil
    end

    return obj
end

-- ====== Rect ======
-- opts: {Pos=Vector2, Size=Vector2, Color=Color3, Transparency=number(0..1), Filled=bool, Thickness=number, Radius=number, ZIndex=number}
function RenderUtil:Rect(opts)
    opts = opts or {}

    local f = Instance.new("Frame")
    f.Name = "Rect"
    f.BorderSizePixel = 0
    f.BackgroundColor3 = opts.Color or Color3.new(1,1,1)
    f.BackgroundTransparency = opts.Transparency or 0
    f.Position = UDim2.fromOffset((opts.Pos and opts.Pos.X) or 0, (opts.Pos and opts.Pos.Y) or 0)
    f.Size = UDim2.fromOffset((opts.Size and opts.Size.X) or 100, (opts.Size and opts.Size.Y) or 50)
    f.ZIndex = opts.ZIndex or self._z
    f.Parent = self.Root

    -- Скругление (всегда можно создать, если Radius > 0)
    local cr
    if (opts.Radius or 0) > 0 then
        cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, opts.Radius)
        cr.Parent = f
    end

    -- Обводка (теперь можно и для Filled=true, если хочешь)
    local st
    if opts.Thickness and opts.Thickness > 0 then
        st = Instance.new("UIStroke")
        st.Thickness = opts.Thickness or 1
        st.Color = opts.StrokeColor or opts.Color or Color3.new(1,1,1)
        st.Transparency = opts.StrokeTransparency or 0
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        st.LineJoinMode = Enum.LineJoinMode.Round -- выглядит мягче на углах
        st.Parent = f
    end

    -- Если это "контурный" прямоугольник (без заливки)
    if opts.Filled == false then
        f.BackgroundTransparency = 1
        if st then
            -- если Filled=false и StrokeColor не задан, пусть берёт opts.Color
            st.Color = opts.StrokeColor or opts.Color or Color3.new(1,1,1)
            st.Transparency = opts.StrokeTransparency or (opts.Transparency or 0)
        else
            -- если юзер попросил Filled=false, но не дал Thickness — сделаем 1
            st = Instance.new("UIStroke")
            st.Thickness = 1
            st.Color = opts.Color or Color3.new(1,1,1)
            st.Transparency = opts.Transparency or 0
            st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            st.LineJoinMode = Enum.LineJoinMode.Round
            st.Parent = f
        end
    end

    -- Внутренние отступы (удобно для текста/иконок внутри)
    local pad
    if opts.Padding then
        pad = Instance.new("UIPadding")
        local p = opts.Padding
        pad.PaddingLeft = UDim.new(0, p.X or p.Left or 0)
        pad.PaddingRight = UDim.new(0, p.X or p.Right or 0)
        pad.PaddingTop = UDim.new(0, p.Y or p.Top or 0)
        pad.PaddingBottom = UDim.new(0, p.Y or p.Bottom or 0)
        pad.Parent = f
    end

    -- Градиент (без картинок, чисто UIGradient)
    local grad
    if opts.Gradient then
        grad = Instance.new("UIGradient")
        grad.Rotation = opts.Gradient.Rotation or 90
        grad.Color = opts.Gradient.Color -- ожидается ColorSequence
        grad.Transparency = opts.Gradient.Transparency -- optional NumberSequence
        grad.Parent = f
    end

    -- Лёгкий "highlight" сверху (делает прямоугольник визуально объемнее)
    -- Это НЕ glow: просто белая полоска с прозрачностью/градиентом.
    local hi
    if opts.Highlight then
        hi = Instance.new("Frame")
        hi.Name = "Highlight"
        hi.BorderSizePixel = 0
        hi.BackgroundColor3 = opts.HighlightColor or Color3.new(1,1,1)
        hi.BackgroundTransparency = opts.HighlightTransparency or 0.88
        hi.Size = UDim2.new(1, 0, 0, math.max(2, math.floor(((opts.HighlightHeight or 10)))))
        hi.Position = UDim2.new(0, 0, 0, 0)
        hi.ZIndex = f.ZIndex + 1
        hi.Parent = f

        local hicr = Instance.new("UICorner")
        hicr.CornerRadius = UDim.new(0, (opts.Radius or 0))
        hicr.Parent = hi

        local hig = Instance.new("UIGradient")
        hig.Rotation = 90
        hig.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        hig.Parent = hi
    end

    return wrap(f, {
        Set = function(p)
            if p.Pos then f.Position = UDim2.fromOffset(p.Pos.X, p.Pos.Y) end
            if p.Size then f.Size = UDim2.fromOffset(p.Size.X, p.Size.Y) end

            if p.Color then
                f.BackgroundColor3 = p.Color
                -- Если StrokeColor не задан отдельно, можно обновлять вместе с Color
                if st and not opts.StrokeColor and not p.StrokeColor then
                    st.Color = p.Color
                end
            end

            if p.Transparency ~= nil then
                f.BackgroundTransparency = (opts.Filled == false) and 1 or p.Transparency
            end

            if p.ZIndex then
                f.ZIndex = p.ZIndex
                if hi then hi.ZIndex = p.ZIndex + 1 end
            end

            -- Stroke настройки
            if st then
                if p.Thickness then st.Thickness = p.Thickness end
                if p.StrokeColor then st.Color = p.StrokeColor end
                if p.StrokeTransparency ~= nil then st.Transparency = p.StrokeTransparency end
            end

            -- Radius
            if p.Radius ~= nil then
                if p.Radius > 0 and not cr then
                    cr = Instance.new("UICorner")
                    cr.Parent = f
                end
                if cr then cr.CornerRadius = UDim.new(0, p.Radius) end
                if hi then
                    local hicr = hi:FindFirstChildOfClass("UICorner")
                    if hicr then hicr.CornerRadius = UDim.new(0, p.Radius) end
                end
            end

            -- Gradient update
            if grad and p.Gradient then
                if p.Gradient.Color then grad.Color = p.Gradient.Color end
                if p.Gradient.Transparency then grad.Transparency = p.Gradient.Transparency end
                if p.Gradient.Rotation then grad.Rotation = p.Gradient.Rotation end
            end

            -- Highlight update
            if hi then
                if p.HighlightColor then hi.BackgroundColor3 = p.HighlightColor end
                if p.HighlightTransparency ~= nil then hi.BackgroundTransparency = p.HighlightTransparency end
                if p.HighlightHeight then
                    hi.Size = UDim2.new(1, 0, 0, math.max(2, math.floor(p.HighlightHeight)))
                end
            end
        end
    })
end

-- ====== Text ======
-- opts: {Pos=Vector2, Size=Vector2, Text=string, Color=Color3, Transparency=number, Outline=bool, OutlineColor=Color3,
--        Font=Enum.Font, TextSize=number, Center=bool, ZIndex=number}
function RenderUtil:Text(opts)
    opts = opts or {}
    local t = Instance.new("TextLabel")
    t.Name = "Text"
    t.BackgroundTransparency = 1
    t.Text = opts.Text or "Text"
    t.Font = opts.Font or Enum.Font.Gotham
    t.TextSize = opts.TextSize or 14
    t.TextColor3 = opts.Color or Color3.new(1,1,1)
    t.TextTransparency = opts.Transparency or 0
    t.RichText = opts.RichText and true or false
    t.TextWrapped = opts.Wrapped and true or false

    local xAlign = opts.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    t.TextXAlignment = xAlign
    t.TextYAlignment = Enum.TextYAlignment.Center

    t.Position = UDim2.fromOffset((opts.Pos and opts.Pos.X) or 0, (opts.Pos and opts.Pos.Y) or 0)
    t.Size = UDim2.fromOffset((opts.Size and opts.Size.X) or 200, (opts.Size and opts.Size.Y) or 20)
    t.ZIndex = opts.ZIndex or self._z
    t.Parent = self.Root

    local st
    if opts.Outline then
        st = Instance.new("UIStroke")
        st.Thickness = 1
        st.Color = opts.OutlineColor or Color3.new(0,0,0)
        st.Transparency = opts.Transparency or 0
        st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        st.Parent = t
    end

    return wrap(t, {
        Set = function(p)
            if p.Pos then t.Position = UDim2.fromOffset(p.Pos.X, p.Pos.Y) end
            if p.Size then t.Size = UDim2.fromOffset(p.Size.X, p.Size.Y) end
            if p.Text ~= nil then t.Text = p.Text end
            if p.Color then t.TextColor3 = p.Color end
            if p.Transparency ~= nil then
                t.TextTransparency = p.Transparency
                if st then st.Transparency = p.Transparency end
            end
            if p.TextSize then t.TextSize = p.TextSize end
            if p.Font then t.Font = p.Font end
            if p.Center ~= nil then
                t.TextXAlignment = p.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
            end
            if p.ZIndex then t.ZIndex = p.ZIndex end
            if p.OutlineColor and st then st.Color = p.OutlineColor end
        end
    })
end

-- ====== Line ======
-- opts: {From=Vector2, To=Vector2, Color=Color3, Transparency=number, Thickness=number, ZIndex=number}
-- Реализовано как тонкий Frame, повёрнутый на угол.
function RenderUtil:Line(opts)
    opts = opts or {}
    local f = Instance.new("Frame")
    f.Name = "Line"
    f.BorderSizePixel = 0
    f.BackgroundColor3 = opts.Color or Color3.new(1,1,1)
    f.BackgroundTransparency = opts.Transparency or 0
    f.AnchorPoint = Vector2.new(0, 0.5)
    f.ZIndex = opts.ZIndex or self._z
    f.Parent = self.Root

    local function update(fromV, toV, thick)
        local dx = toV.X - fromV.X
        local dy = toV.Y - fromV.Y
        local len = math.sqrt(dx*dx + dy*dy)
        local angle = math.deg(math.atan2(dy, dx))

        f.Position = UDim2.fromOffset(fromV.X, fromV.Y)
        f.Size = UDim2.fromOffset(len, thick or 1)
        f.Rotation = angle
    end

    local fromV = opts.From or Vector2.new(0,0)
    local toV = opts.To or Vector2.new(100,0)
    update(fromV, toV, opts.Thickness or 1)

    return wrap(f, {
        Set = function(p)
            if p.Color then f.BackgroundColor3 = p.Color end
            if p.Transparency ~= nil then f.BackgroundTransparency = p.Transparency end
            if p.ZIndex then f.ZIndex = p.ZIndex end

            local nf = p.From or fromV
            local nt = p.To or toV
            local th = p.Thickness or opts.Thickness or 1
            fromV, toV = nf, nt
            update(fromV, toV, th)
        end
    })
end

return RenderUtil
