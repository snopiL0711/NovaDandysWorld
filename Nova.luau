--// NOVA CONTROL PANEL

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local running = true

local staminaEnabled = false
local speedEnabled = false
local selectedSpeed = 20

local espEnabled = {
    Players = false,
    Generators = false,
    Twisteds = false,
    Items = false
}

local skillCheckEnabled = false

local connections = {}
local espObjects = {}
local staminaConnections = {}

local BLUE = Color3.fromRGB(55, 145, 255)
local GREEN = Color3.fromRGB(50, 225, 115)
local RED = Color3.fromRGB(255, 65, 75)
local YELLOW = Color3.fromRGB(255, 215, 0)

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

--==================================================
-- GUI HELPERS
--==================================================

local function create(class, properties, parent)
    local obj = Instance.new(class)

    for k, v in pairs(properties) do
        obj[k] = v
    end

    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, obj)
end

local function tween(instance, duration, properties, style, direction)
    local info = TweenInfo.new(
        duration or 0.25,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(instance, info, properties)
    t:Play()
    return t
end

-- Mobile detection & responsive scaling
local isMobile = UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)
local MOBILE_SCALE = 0.8
local PC_SCALE = 1.0
local currentScale = isMobile and MOBILE_SCALE or PC_SCALE

local normalWidth = 300
local normalHeight = 470
local minimizedHeight = 44

local startOffsetX = -(normalWidth * currentScale) / 2
local startOffsetY = -(normalHeight * currentScale) / 2

local gui = create("ScreenGui", {
    Name = "NovaControlPanel",
    ResetOnSpawn = false,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local main = create("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(normalWidth, normalHeight),
    Position = UDim2.new(0.5, startOffsetX, 0.5, startOffsetY),
    BackgroundColor3 = Color3.fromRGB(15, 18, 27),
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)

round(main, 14)

create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 27, 41)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 17, 26))
    }),
    Rotation = 45
}, main)

local mainStroke = create("UIStroke", {
    Color = Color3.fromRGB(70, 95, 155),
    Thickness = 1.2
}, main)

create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 140, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(55, 80, 140)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 45, 80))
    }),
    Rotation = 35
}, mainStroke)

local uiScale = create("UIScale", {
    Scale = currentScale
}, main)

--==================================================
-- TOPBAR
--==================================================

local topbar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(22, 28, 43),
    BorderSizePixel = 0,
    Active = true
}, main)

round(topbar, 14)

create("Frame", {
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = Color3.fromRGB(22, 28, 43),
    BorderSizePixel = 0
}, topbar)

create("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(45, 60, 95),
    BorderSizePixel = 0
}, topbar)

local badge = create("Frame", {
    Size = UDim2.fromOffset(46, 20),
    Position = UDim2.new(0, 12, 0.5, -10),
    BackgroundColor3 = Color3.fromRGB(35, 75, 155),
    BorderSizePixel = 0
}, topbar)

round(badge, 5)

create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "NOVA",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, badge)

create("TextLabel", {
    Size = UDim2.new(1, -165, 1, 0),
    Position = UDim2.fromOffset(66, 0),
    BackgroundTransparency = 1,
    Text = "Control Panel",
    TextColor3 = Color3.fromRGB(215, 225, 245),
    TextSize = 13,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, topbar)

local minimizeBtn = create("TextButton", {
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.new(1, -100, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(38, 48, 72),
    Text = "−",
    TextColor3 = Color3.fromRGB(220, 230, 255),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false
}, topbar)

round(minimizeBtn, 6)

local unload = create("TextButton", {
    Size = UDim2.fromOffset(60, 26),
    Position = UDim2.new(1, -69, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(180, 55, 65),
    Text = "Unload",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false
}, topbar)

round(unload, 6)

connect(minimizeBtn.MouseEnter, function()
    tween(minimizeBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(52, 66, 98)})
end)
connect(minimizeBtn.MouseLeave, function()
    tween(minimizeBtn, 0.18, {BackgroundColor3 = Color3.fromRGB(38, 48, 72)})
end)

connect(unload.MouseEnter, function()
    tween(unload, 0.18, {BackgroundColor3 = Color3.fromRGB(215, 65, 75)})
end)
connect(unload.MouseLeave, function()
    tween(unload, 0.18, {BackgroundColor3 = Color3.fromRGB(180, 55, 65)})
end)

--==================================================
-- CONTENT
--==================================================

local content = create("ScrollingFrame", {
    Position = UDim2.fromOffset(8, 52),
    Size = UDim2.new(1, -16, 1, -60),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(100, 130, 190),
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, main)

create("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, content)

create("UIPadding", {
    PaddingLeft = UDim.new(0, 3),
    PaddingRight = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 8)
}, content)

--==================================================
-- MINIMIZE / EXPAND & TOGGLE SYSTEM
--==================================================

local isMinimized = false

local function setMinimized(minimized)
    isMinimized = minimized

    if isMinimized then
        minimizeBtn.Text = "+"
        content.Visible = false
        tween(main, 0.24, {Size = UDim2.fromOffset(normalWidth, minimizedHeight)})
    else
        minimizeBtn.Text = "−"
        tween(main, 0.24, {Size = UDim2.fromOffset(normalWidth, normalHeight)})
        task.delay(0.1, function()
            if not isMinimized then
                content.Visible = true
            end
        end)
    end
end

connect(minimizeBtn.MouseButton1Click, function()
    setMinimized(not isMinimized)
end)

local isWindowVisible = true
local isAnimatingVisibility = false

local function toggleGuiVisibility()
    if isAnimatingVisibility then return end
    isAnimatingVisibility = true

    if isWindowVisible then
        isWindowVisible = false
        tween(uiScale, 0.18, {Scale = currentScale * 0.8}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.18, function()
            if not isWindowVisible then
                main.Visible = false
            end
            isAnimatingVisibility = false
        end)
    else
        isWindowVisible = true
        main.Visible = true
        uiScale.Scale = currentScale * 0.8
        tween(uiScale, 0.25, {Scale = currentScale}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        task.delay(0.25, function()
            isAnimatingVisibility = false
        end)
    end
end

-- Keybind to toggle GUI (PC: RightControl / Insert)
connect(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
        toggleGuiVisibility()
    end
end)

-- Floating Toggle Button (draggable mini-button, useful for mobile and quick access)
local floatingToggle = create("TextButton", {
    Name = "NovaToggle",
    Size = UDim2.fromOffset(40, 40),
    Position = UDim2.new(0, 15, 0.45, 0),
    BackgroundColor3 = Color3.fromRGB(22, 28, 43),
    BorderSizePixel = 0,
    Text = "N",
    TextColor3 = BLUE,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Active = true
}, gui)

round(floatingToggle, 12)

local floatStroke = create("UIStroke", {
    Color = Color3.fromRGB(75, 110, 185),
    Thickness = 1.3
}, floatingToggle)

create("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 36, 56)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 22, 34))
    }),
    Rotation = 45
}, floatingToggle)

local floatScale = create("UIScale", {
    Scale = currentScale
}, floatingToggle)

connect(floatingToggle.MouseEnter, function()
    tween(floatingToggle, 0.2, {BackgroundColor3 = Color3.fromRGB(32, 42, 66)})
    tween(floatStroke, 0.2, {Color = Color3.fromRGB(95, 145, 255)})
end)

connect(floatingToggle.MouseLeave, function()
    tween(floatingToggle, 0.2, {BackgroundColor3 = Color3.fromRGB(22, 28, 43)})
    tween(floatStroke, 0.2, {Color = Color3.fromRGB(75, 110, 185)})
end)

local floatDragging = false
local floatDragStart = Vector3.zero
local floatStartPos = UDim2.new()
local floatMoved = false

connect(floatingToggle.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        floatDragging = true
        floatMoved = false
        floatDragStart = input.Position
        floatStartPos = floatingToggle.Position
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not floatDragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - floatDragStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            floatMoved = true
            floatingToggle.Position = UDim2.new(
                floatStartPos.X.Scale,
                floatStartPos.X.Offset + delta.X,
                floatStartPos.Y.Scale,
                floatStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if floatDragging then
            floatDragging = false
            if not floatMoved then
                tween(floatScale, 0.08, {Scale = currentScale * 0.88})
                task.delay(0.08, function()
                    tween(floatScale, 0.16, {Scale = currentScale}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end)
                toggleGuiVisibility()
            end
        end
    end
end)

local function section(name)
    local secFrame = create("Frame", {
        Size = UDim2.new(1, -4, 0, 24),
        BackgroundTransparency = 1
    }, content)

    local bar = create("Frame", {
        Size = UDim2.fromOffset(3, 12),
        Position = UDim2.new(0, 2, 0.5, -6),
        BackgroundColor3 = BLUE,
        BorderSizePixel = 0
    }, secFrame)
    round(bar, 2)

    create("TextLabel", {
        Size = UDim2.new(1, -15, 1, 0),
        Position = UDim2.fromOffset(11, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(130, 165, 235),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, secFrame)
end

--==================================================
-- TOGGLE
--==================================================

local function toggleRow(name, initial, callback)
    local row = create("TextButton", {
        Size = UDim2.new(1, -4, 0, 41),
        BackgroundColor3 = Color3.fromRGB(24, 29, 43),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, content)

    round(row, 8)

    local rowStroke = create("UIStroke", {
        Color = Color3.fromRGB(50, 65, 95),
        Thickness = 1,
        Transparency = 0.5
    }, row)

    create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(225, 230, 245),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local pill = create("Frame", {
        Size = UDim2.fromOffset(44, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = initial and Color3.fromRGB(35, 175, 110) or Color3.fromRGB(48, 56, 76),
        BorderSizePixel = 0
    }, row)

    round(pill, 11)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = initial and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    }, pill)

    round(knob, 8)

    local state = initial

    local function animateSwitch(targetState)
        if targetState then
            tween(pill, 0.22, {BackgroundColor3 = Color3.fromRGB(35, 175, 110)})
            tween(knob, 0.22, {Position = UDim2.new(1, -19, 0.5, -8)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            tween(pill, 0.22, {BackgroundColor3 = Color3.fromRGB(48, 56, 76)})
            tween(knob, 0.22, {Position = UDim2.new(0, 3, 0.5, -8)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end

    connect(row.MouseEnter, function()
        tween(row, 0.18, {BackgroundColor3 = Color3.fromRGB(30, 37, 55)})
        tween(rowStroke, 0.18, {Transparency = 0.15})
    end)

    connect(row.MouseLeave, function()
        tween(row, 0.18, {BackgroundColor3 = Color3.fromRGB(24, 29, 43)})
        tween(rowStroke, 0.18, {Transparency = 0.5})
    end)

    connect(row.MouseButton1Click, function()
        state = not state
        animateSwitch(state)
        callback(state)
    end)

    return function(value)
        state = value
        animateSwitch(state)
        callback(state)
    end
end

--==================================================
-- STAMINA HANDLER
--==================================================

local function findStaminaStats()
    local ingameFolder = Workspace:FindFirstChild("IngamePlayers")
    local ingameChar = ingameFolder and ingameFolder:FindFirstChild(LocalPlayer.Name)
    local normalChar = LocalPlayer.Character

    local targetChar = ingameChar or normalChar
    if not targetChar then
        return nil, nil
    end

    local stats = targetChar:FindFirstChild("Stats") or targetChar:FindFirstChild("PlayerStats")
    if stats then
        local current = stats:FindFirstChild("CurrentStamina") or stats:FindFirstChild("Stamina")
        local original = stats:FindFirstChild("OriginalStamina") or stats:FindFirstChild("MaxStamina")
        if current and original and current:IsA("ValueBase") and original:IsA("ValueBase") then
            return current, original
        end
    end

    local curDirect = targetChar:FindFirstChild("CurrentStamina") or targetChar:FindFirstChild("Stamina")
    local origDirect = targetChar:FindFirstChild("OriginalStamina") or targetChar:FindFirstChild("MaxStamina")
    if curDirect and origDirect and curDirect:IsA("ValueBase") and origDirect:IsA("ValueBase") then
        return curDirect, origDirect
    end

    return nil, nil
end

local function hookStamina()
    for _, conn in ipairs(staminaConnections) do
        conn:Disconnect()
    end
    table.clear(staminaConnections)

    if not staminaEnabled then
        return
    end

    local current, original = findStaminaStats()
    if current and original then
        current.Value = original.Value
        local c = current:GetPropertyChangedSignal("Value"):Connect(function()
            if staminaEnabled and current.Value < original.Value then
                current.Value = original.Value
            end
        end)
        table.insert(staminaConnections, c)
    end
end

--==================================================
-- PLAYER
--==================================================

section("PLAYER")

toggleRow("Inf Stamina", false, function(value)
    staminaEnabled = value
    if value then
        hookStamina()
    else
        for _, conn in ipairs(staminaConnections) do
            conn:Disconnect()
        end
        table.clear(staminaConnections)
    end
end)

--==================================================
-- CUSTOM SPEED
--==================================================

local speedRow = create("Frame", {
    Size = UDim2.new(1, -4, 0, 42),
    BackgroundColor3 = Color3.fromRGB(24, 29, 43),
    BorderSizePixel = 0
}, content)

round(speedRow, 8)

local speedRowStroke = create("UIStroke", {
    Color = Color3.fromRGB(50, 65, 95),
    Thickness = 1,
    Transparency = 0.5
}, speedRow)

create("TextLabel", {
    Size = UDim2.new(1, -115, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "Custom Speed",
    TextColor3 = Color3.fromRGB(225, 230, 245),
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, speedRow)

local speedButton = create("TextButton", {
    Size = UDim2.fromOffset(85, 26),
    Position = UDim2.new(1, -96, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(45, 75, 135),
    BorderSizePixel = 0,
    Text = "20  ▼",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, speedRow)

round(speedButton, 6)

connect(speedButton.MouseEnter, function()
    tween(speedButton, 0.18, {BackgroundColor3 = Color3.fromRGB(58, 95, 170)})
end)
connect(speedButton.MouseLeave, function()
    tween(speedButton, 0.18, {BackgroundColor3 = Color3.fromRGB(45, 75, 135)})
end)

local speedMenu = create("Frame", {
    Size = UDim2.new(1, -4, 0, 0),
    BackgroundColor3 = Color3.fromRGB(20, 24, 36),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false
}, content)

round(speedMenu, 8)

create("UIStroke", {
    Color = Color3.fromRGB(45, 60, 90),
    Thickness = 1,
    Transparency = 0.5
}, speedMenu)

create("UIListLayout", {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder
}, speedMenu)

create("UIPadding", {
    PaddingTop = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 4)
}, speedMenu)

local speeds = {20, 22.5, 25, 27.5, 30}
local speedMenuOpen = false

local function toggleSpeedMenu()
    speedMenuOpen = not speedMenuOpen
    if speedMenuOpen then
        speedMenu.Visible = true
        speedButton.Text = tostring(selectedSpeed) .. "  ▲"
        tween(speedMenu, 0.25, {Size = UDim2.new(1, -4, 0, 157)}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        speedButton.Text = tostring(selectedSpeed) .. "  ▼"
        tween(speedMenu, 0.2, {Size = UDim2.new(1, -4, 0, 0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.2, function()
            if not speedMenuOpen then
                speedMenu.Visible = false
            end
        end)
    end
end

connect(speedButton.MouseButton1Click, toggleSpeedMenu)

for _, speed in ipairs(speeds) do
    local option = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(35, 42, 60),
        BorderSizePixel = 0,
        Text = tostring(speed),
        TextColor3 = Color3.fromRGB(220, 230, 250),
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    }, speedMenu)

    round(option, 5)

    connect(option.MouseEnter, function()
        tween(option, 0.15, {BackgroundColor3 = Color3.fromRGB(50, 65, 95)})
    end)
    connect(option.MouseLeave, function()
        tween(option, 0.15, {BackgroundColor3 = Color3.fromRGB(35, 42, 60)})
    end)

    connect(option.MouseButton1Click, function()
        selectedSpeed = speed
        toggleSpeedMenu()
    end)
end

toggleRow("Enable Custom Speed", false, function(value)
    speedEnabled = value
end)

--==================================================
-- AUTO SKILL CHECK
--==================================================

section("TOOLS")

toggleRow("Auto Skill Check", false, function(value)
    skillCheckEnabled = value
end)

local skillEvent = ReplicatedStorage:FindFirstChild("AutoSkillCheck")
local skillElapsed = 0
local wasInside = false
local lastSkillEvent = 0
local lastCircleSkillEvent = 0
local circleSawStart = false
local circleTriggered = false

--==================================================
-- ESP HELPERS
--==================================================

section("ESP  |  MULTI SELECT")

local function getPart(target)
    if target:IsA("BasePart") then
        return target
    end

    if target:IsA("Model") then
        return target.PrimaryPart
            or target:FindFirstChild("HumanoidRootPart", true)
            or target:FindFirstChild("Head", true)
            or target:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function removeESP(target)
    local data = espObjects[target]
    if not data then
        return
    end

    if data.highlight then
        data.highlight:Destroy()
    end

    if data.tag then
        data.tag:Destroy()
    end

    espObjects[target] = nil
end

local function addESP(kind, target, tagText, color, seen)
    if not target:IsA("Model") and not target:IsA("BasePart") then
        return
    end

    seen[target] = true

    local data = espObjects[target]

    if not data then
        local highlight = create("Highlight", {
            Name = "Nova_LocalHighlight",
            Adornee = target,
            FillColor = color,
            OutlineColor = color,
            FillTransparency = 0.72,
            OutlineTransparency = 0,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        }, Workspace)

        data = {
            kind = kind,
            highlight = highlight,
            tag = nil,
            label = nil,
            text = tagText
        }

        espObjects[target] = data
    end

    data.highlight.Adornee = target
    data.highlight.FillColor = color
    data.highlight.OutlineColor = color
    data.kind = kind
    data.text = tagText

    local part = getPart(target)

    if not part then
        if data.tag then
            data.tag:Destroy()
            data.tag = nil
            data.label = nil
        end
        return
    end

    if not data.tag or data.tag.Adornee ~= part then
        if data.tag then
            data.tag:Destroy()
        end

        data.tag = create("BillboardGui", {
            Name = "Nova_LocalTag",
            Adornee = part,
            Size = UDim2.fromOffset(180, 28),
            StudsOffset = Vector3.new(0, 3, 0),
            AlwaysOnTop = true,
            LightInfluence = 0,
            MaxDistance = 500
        }, PlayerGui)

        data.label = create("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = tagText,
            TextColor3 = color,
            TextStrokeColor3 = Color3.new(0, 0, 0),
            TextStrokeTransparency = 0.25,
            TextSize = 13,
            Font = Enum.Font.GothamBold
        }, data.tag)
    end

    data.label.Text = tagText
    data.label.TextColor3 = color
end

--==================================================
-- ESP TOGGLES
--==================================================

toggleRow("Players", false, function(value)
    espEnabled.Players = value
end)

toggleRow("Generators", false, function(value)
    espEnabled.Generators = value
end)

toggleRow("Twisteds", false, function(value)
    espEnabled.Twisteds = value
end)

toggleRow("Items (Tape / Meds / Pumpkin)", false, function(value)
    espEnabled.Items = value
end)

--==================================================
-- ESP SCANNER
--==================================================

local function isChildOfMatchedModel(obj, pattern)
    local parent = obj.Parent
    while parent and parent ~= Workspace and parent.Name ~= "CurrentRoom" do
        if parent:IsA("Model") and parent.Name:find(pattern) then
            return true
        end
        parent = parent.Parent
    end
    return false
end

local function updateESP()
    local seen = {}

    -- PLAYERS
    if espEnabled.Players then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                addESP("Players", player.Character, player.Name, BLUE, seen)
            end
        end
    end

    -- CURRENTROOM SCANNING (GENERATORS, MONSTERS, ITEMS)
    local room = Workspace:FindFirstChild("CurrentRoom")
    if room then
        local descendants = room:GetDescendants()

        for _, obj in ipairs(descendants) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local objName = obj.Name

                -- GENERATORS (Поиск всех генераторов и DualGen в CurrentRoom)
                if espEnabled.Generators then
                    if objName == "Generator" or (obj:IsA("Model") and objName:find("Generator")) then
                        addESP("Generators", obj, "Generator", GREEN, seen)
                    elseif objName:find("DualGen") and (obj:IsA("Model") or not (obj.Parent and obj.Parent.Name:find("DualGen"))) then
                        addESP("Generators", obj, "DualGen", GREEN, seen)
                    end
                end

                -- TWISTEDS (Поиск монстров по всему CurrentRoom)
                if espEnabled.Twisteds then
                    if obj:IsA("Model") and objName:find("Monster$") then
                        local twistedName = objName:gsub("Monster$", "")
                        addESP("Twisteds", obj, "Twisted " .. twistedName, RED, seen)
                    end
                end

                -- ITEMS (Research Capsule / Tape / Pumpkin / Bandage / Medkit)
                if espEnabled.Items then
                    if objName == "ResearchCapsule" or objName:find("ResearchCapsule") then
                        if obj:IsA("Model") or not isChildOfMatchedModel(obj, "ResearchCapsule") then
                            addESP("Items", obj, "Research Capsule", YELLOW, seen)
                        end
                    elseif objName == "Tape" or objName:find("^Tape") then
                        if obj:IsA("Model") or not isChildOfMatchedModel(obj, "Tape") then
                            addESP("Items", obj, "Tape", YELLOW, seen)
                        end
                    elseif objName == "Pumpkin" or objName:find("Pumpkin") then
                        if obj:IsA("Model") or not isChildOfMatchedModel(obj, "Pumpkin") then
                            addESP("Items", obj, "Pumpkin", YELLOW, seen)
                        end
                    elseif objName == "Bandage" or objName:find("Bandage") then
                        if obj:IsA("Model") or not isChildOfMatchedModel(obj, "Bandage") then
                            addESP("Items", obj, "Bandage", YELLOW, seen)
                        end
                    elseif objName == "Medkit" or objName:find("Medkit") or objName:find("MedKit") then
                        if obj:IsA("Model") or not isChildOfMatchedModel(obj, "Med") then
                            addESP("Items", obj, "Medkit", YELLOW, seen)
                        end
                    end
                end
            end
        end
    end

    -- REMOVE OLD ESP
    for target in pairs(espObjects) do
        if not target.Parent or not seen[target] then
            removeESP(target)
        end
    end
end

--==================================================
-- LOOPS & INPUT
--==================================================

-- Выносливость / Скорость
task.spawn(function()
    while running do
        if staminaEnabled then
            local current, original = findStaminaStats()
            if current and original then
                if current.Value < original.Value then
                    current.Value = original.Value
                end
                if #staminaConnections == 0 then
                    hookStamina()
                end
            end
        end

        if speedEnabled then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = selectedSpeed
            end
        end

        task.wait(0.2)
    end
end)

-- Респавн
connect(LocalPlayer.CharacterAdded, function()
    task.wait(0.5)
    if staminaEnabled then
        hookStamina()
    end
end)

-- SKILL CHECK DETECTION (SPACE PRESS)
connect(RunService.Heartbeat, function(deltaTime)
    if not running or not skillCheckEnabled then
        wasInside = false
        circleSawStart = false
        circleTriggered = false
        return
    end

    skillElapsed += deltaTime
    if skillElapsed < 0.01 then
        return
    end
    skillElapsed = 0

    local function pressSpace()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)

        if skillEvent and skillEvent:IsA("BindableEvent") then
            skillEvent:Fire("Space")
        end
    end

    -- 1) LINEAR SKILL CHECK (ScreenGui -> Menu -> SkillCheckFrame)
    local screen = PlayerGui:FindFirstChild("ScreenGui")
    local menu = screen and screen:FindFirstChild("Menu")
    local frame = menu and menu:FindFirstChild("SkillCheckFrame")
    local marker = frame and frame:FindFirstChild("Marker")
    local gold = frame and frame:FindFirstChild("GoldArea")

    if frame and marker and gold and frame.Visible then
        local markerX = marker.AbsolutePosition.X + (marker.AbsoluteSize.X / 2)
        local minX = gold.AbsolutePosition.X
        local maxX = minX + gold.AbsoluteSize.X

        local inside = markerX >= minX and markerX <= maxX

        if inside and not wasInside and (os.clock() - lastSkillEvent > 0.15) then
            lastSkillEvent = os.clock()
            pressSpace()
        end

        wasInside = inside
    else
        wasInside = false
    end

    -- 2) CIRCLE SKILL CHECK (CircleSkillCheckGui -> SkillCheckFrame -> Container)
    local circleGui = PlayerGui:FindFirstChild("CircleSkillCheckGui")
    local circleFrame = circleGui and circleGui:FindFirstChild("SkillCheckFrame")
    local circleContainer = circleFrame and circleFrame:FindFirstChild("Container")
    local shrinking = circleContainer and circleContainer:FindFirstChild("ShrinkingCircle")
    local yellow = circleContainer and circleContainer:FindFirstChild("YellowCircle")

    local circleActive = circleGui and circleGui.Enabled
        and circleFrame and circleFrame.Visible
        and circleContainer and circleContainer.Visible
        and shrinking and shrinking.Visible
        and yellow and yellow.Visible

    if circleActive then
        local shrinkSize = shrinking.AbsoluteSize.X
        local yellowSize = yellow.AbsoluteSize.X

        if yellowSize >= 20 then
            local targetSize = yellowSize - 20

            if shrinkSize > targetSize then
                circleSawStart = true
            end

            if (circleSawStart or shrinkSize >= targetSize - 30)
                and not circleTriggered
                and shrinkSize <= targetSize
                and shrinkSize >= (targetSize - 40)
                and (os.clock() - lastCircleSkillEvent > 0.2) then

                circleTriggered = true
                lastCircleSkillEvent = os.clock()
                pressSpace()
            end
        end
    else
        circleSawStart = false
        circleTriggered = false
    end
end)

-- ESP LOOP
task.spawn(function()
    while running do
        updateESP()
        task.wait(0.5)
    end
end)

--==================================================
-- DRAG WINDOW
--==================================================

local dragging = false
local dragStart
local startPosition

connect(topbar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

--==================================================
-- UNLOAD
--==================================================

local function unloadGUI()
    if not running then
        return
    end

    running = false

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end

    for _, connection in ipairs(staminaConnections) do
        connection:Disconnect()
    end

    for target in pairs(espObjects) do
        removeESP(target)
    end

    table.clear(espObjects)
    table.clear(connections)
    table.clear(staminaConnections)

    gui:Destroy()
end

connect(unload.MouseButton1Click, unloadGUI)

print("[NOVA] Control Panel Loaded :)")

-- Spawn animation
uiScale.Scale = currentScale * 0.75
tween(uiScale, 0.35, {Scale = currentScale}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
