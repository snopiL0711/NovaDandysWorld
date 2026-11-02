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

-- Mobile detection & responsive scaling
local isMobile = UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled and UserInputService.MouseEnabled)
local MOBILE_SCALE = 0.8
local PC_SCALE = 1.0
local currentScale = isMobile and MOBILE_SCALE or PC_SCALE

local normalWidth = 300
local normalHeight = 470
local minimizedHeight = 43

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
    BackgroundColor3 = Color3.fromRGB(17, 20, 30),
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)

round(main, 12)

create("UIScale", {
    Scale = currentScale
}, main)

create("UIStroke", {
    Color = Color3.fromRGB(75, 105, 165),
    Thickness = 1.3
}, main)

--==================================================
-- TOPBAR
--==================================================

local topbar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 43),
    BackgroundColor3 = Color3.fromRGB(27, 33, 49),
    BorderSizePixel = 0,
    Active = true
}, main)

round(topbar, 12)

create("TextLabel", {
    Size = UDim2.new(1, -118, 1, 0),
    Position = UDim2.fromOffset(13, 0),
    BackgroundTransparency = 1,
    Text = "NOVA  |  Control Panel",
    TextColor3 = Color3.fromRGB(220, 230, 255),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd
}, topbar)

local minimizeBtn = create("TextButton", {
    Size = UDim2.fromOffset(27, 27),
    Position = UDim2.new(1, -107, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(48, 57, 79),
    Text = "−",
    TextColor3 = Color3.fromRGB(220, 230, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = true
}, topbar)

round(minimizeBtn, 6)

local unload = create("TextButton", {
    Size = UDim2.fromOffset(65, 27),
    Position = UDim2.new(1, -75, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(190, 65, 75),
    Text = "Unload",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, topbar)

round(unload, 6)

--==================================================
-- CONTENT
--==================================================

local content = create("ScrollingFrame", {
    Position = UDim2.fromOffset(8, 51),
    Size = UDim2.new(1, -16, 1, -59),
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
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(normalWidth, minimizedHeight)
        }):Play()
    else
        minimizeBtn.Text = "−"
        local tween = TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(normalWidth, normalHeight)
        })
        tween:Play()
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

local function toggleGuiVisibility()
    main.Visible = not main.Visible
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
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.new(0, 15, 0.45, 0),
    BackgroundColor3 = Color3.fromRGB(27, 33, 49),
    BorderSizePixel = 0,
    Text = "N",
    TextColor3 = BLUE,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    Active = true
}, gui)

round(floatingToggle, 9)

create("UIStroke", {
    Color = Color3.fromRGB(75, 105, 165),
    Thickness = 1.3
}, floatingToggle)

create("UIScale", {
    Scale = currentScale
}, floatingToggle)

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
                toggleGuiVisibility()
            end
        end
    end
end)

local function section(name)
    create("TextLabel", {
        Size = UDim2.new(1, -4, 0, 23),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(120, 160, 235),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, content)
end

--==================================================
-- TOGGLE
--==================================================

local function toggleRow(name, initial, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, -4, 0, 41),
        BackgroundColor3 = Color3.fromRGB(29, 34, 49),
        BorderSizePixel = 0
    }, content)

    round(row, 8)

    create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.fromOffset(11, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(225, 230, 245),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)

    local state = initial

    local button = create("TextButton", {
        Size = UDim2.fromOffset(66, 26),
        Position = UDim2.new(1, -77, 0.5, -13),
        BorderSizePixel = 0,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false
    }, row)

    round(button, 6)

    local function update()
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state
            and Color3.fromRGB(35, 165, 115)
            or Color3.fromRGB(65, 71, 88)
    end

    update()

    connect(button.MouseButton1Click, function()
        state = not state
        update()
        callback(state)
    end)

    return function(value)
        state = value
        update()
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
    BackgroundColor3 = Color3.fromRGB(29, 34, 49),
    BorderSizePixel = 0
}, content)

round(speedRow, 8)

create("TextLabel", {
    Size = UDim2.new(1, -115, 1, 0),
    Position = UDim2.fromOffset(11, 0),
    BackgroundTransparency = 1,
    Text = "Custom Speed",
    TextColor3 = Color3.fromRGB(225, 230, 245),
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, speedRow)

local speedButton = create("TextButton", {
    Size = UDim2.fromOffset(85, 27),
    Position = UDim2.new(1, -96, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(55, 90, 155),
    BorderSizePixel = 0,
    Text = "20  v",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.GothamBold
}, speedRow)

round(speedButton, 6)

local speedMenu = create("Frame", {
    Size = UDim2.new(1, -4, 0, 0),
    BackgroundColor3 = Color3.fromRGB(29, 34, 49),
    BorderSizePixel = 0,
    Visible = false
}, content)

round(speedMenu, 8)

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

connect(speedButton.MouseButton1Click, function()
    speedMenu.Visible = not speedMenu.Visible
    speedMenu.Size = speedMenu.Visible
        and UDim2.new(1, -4, 0, 157)
        or UDim2.new(1, -4, 0, 0)
end)

for _, speed in ipairs(speeds) do
    local option = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(48, 57, 79),
        BorderSizePixel = 0,
        Text = tostring(speed),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        Font = Enum.Font.GothamMedium
    }, speedMenu)

    round(option, 5)

    connect(option.MouseButton1Click, function()
        selectedSpeed = speed
        speedButton.Text = tostring(speed) .. "  v"
        speedMenu.Visible = false
        speedMenu.Size = UDim2.new(1, -4, 0, 0)
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

toggleRow("Items (Capsules / Tape)", false, function(value)
    espEnabled.Items = value
end)

--==================================================
-- ESP SCANNER
--==================================================

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

                -- GENERATORS (Поиск всех генераторов в CurrentRoom)
                if espEnabled.Generators then
                    if objName == "Generator" or (obj:IsA("Model") and objName:find("Generator")) then
                        addESP("Generators", obj, "Generator", GREEN, seen)
                    end
                end

                -- TWISTEDS (Поиск монстров по всему CurrentRoom)
                if espEnabled.Twisteds then
                    if obj:IsA("Model") and objName:find("Monster$") then
                        local twistedName = objName:gsub("Monster$", "")
                        addESP("Twisteds", obj, "Twisted " .. twistedName, RED, seen)
                    end
                end

                -- ITEMS (Research Capsule & Tape)
                if espEnabled.Items then
                    if objName == "ResearchCapsule" or objName:find("ResearchCapsule") then
                        addESP("Items", obj, "Research Capsule", YELLOW, seen)
                    elseif objName == "Tape" or objName:find("^Tape") then
                        addESP("Items", obj, "Tape", YELLOW, seen)
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
        return
    end

    skillElapsed += deltaTime
    if skillElapsed < 0.01 then
        return
    end
    skillElapsed = 0

    local screen = PlayerGui:FindFirstChild("ScreenGui")
    local menu = screen and screen:FindFirstChild("Menu")
    local frame = menu and menu:FindFirstChild("SkillCheckFrame")
    local marker = frame and frame:FindFirstChild("Marker")
    local gold = frame and frame:FindFirstChild("GoldArea")

    if not frame or not marker or not gold or not frame.Visible then
        wasInside = false
        return
    end

    local markerX = marker.AbsolutePosition.X + (marker.AbsoluteSize.X / 2)
    local minX = gold.AbsolutePosition.X
    local maxX = minX + gold.AbsoluteSize.X

    local inside = markerX >= minX and markerX <= maxX

    if inside and not wasInside and (os.clock() - lastSkillEvent > 0.15) then
        lastSkillEvent = os.clock()

        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)

        if skillEvent and skillEvent:IsA("BindableEvent") then
            skillEvent:Fire("Space")
        end
    end

    wasInside = inside
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
