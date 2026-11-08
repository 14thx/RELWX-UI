-- RELWX Settings Only
-- Standalone Roblox LocalScript: UI settings only.
-- All game automation, remotes, scanning, teleporting, farming, and external integrations removed.
-- Settings are held in memory for this session only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("RELWX_SettingsOnly")
if old then old:Destroy() end

local state = {
    scale = 1,
    sound = true,
    accent = Color3.fromRGB(201, 203, 211),
    background = Color3.fromRGB(10, 10, 12),
}

local content

local gui = Instance.new("ScreenGui")
gui.Name = "RELWX_SettingsOnly"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Window"
root.Size = UDim2.fromOffset(420, 430)
root.Position = UDim2.new(0.5, -210, 0.5, -215)
root.BackgroundColor3 = state.background
root.BorderSizePixel = 0
root.Parent = gui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 14)
local rootStroke = Instance.new("UIStroke", root)
rootStroke.Color = state.accent
rootStroke.Transparency = 0.35

local scaler = Instance.new("UIScale")
scaler.Scale = state.scale
scaler.Parent = root

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end

local function label(parent, text, size, position, dimensions, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextSize = size,
        Position = position,
        Size = dimensions,
        TextColor3 = color or Color3.fromRGB(240, 240, 244),
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

local function button(parent, text, position, dimensions, callback)
    local b = make("TextButton", {
        Text = text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextColor3 = Color3.fromRGB(242, 242, 246),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        BorderSizePixel = 0,
        Position = position,
        Size = dimensions,
        AutoButtonColor = true,
    }, parent)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.Activated:Connect(function()
        if state.sound then
            -- Lightweight UI feedback only; no game action is triggered.
            pcall(function()
                local s = Instance.new("Sound")
                s.SoundId = "rbxasset://sounds/button.wav"
                s.Volume = 0.25
                s.Parent = root
                s:Play()
                game:GetService("Debris"):AddItem(s, 2)
            end)
        end
        if callback then callback() end
    end)
    return b
end

local header = make("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -24, 0, 54),
    Position = UDim2.fromOffset(12, 8),
}, root)
label(header, "RELWX  /  ตั้งค่า", 18, UDim2.fromOffset(8, 0), UDim2.new(1, -90, 1, 0), nil, Enum.Font.GothamBold)
local minimize = button(header, "—", UDim2.new(1, -74, 0, 8), UDim2.fromOffset(30, 30), function()
    content.Visible = not content.Visible
    root.Size = content.Visible and UDim2.fromOffset(420, 430) or UDim2.fromOffset(420, 70)
end)
local close = button(header, "×", UDim2.new(1, -38, 0, 8), UDim2.fromOffset(30, 30), function()
    root.Visible = false
end)

content = make("Frame", {
    Name = "SettingsContent",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 72),
    Size = UDim2.new(1, -40, 1, -88),
}, root)

local function section(text, y)
    label(content, text, 12, UDim2.fromOffset(2, y), UDim2.new(1, -4, 0, 24), Color3.fromRGB(170, 172, 184), Enum.Font.GothamBold)
end

section("รูปลักษณ์", 0)
label(content, "ขนาดหน้าต่าง", 13, UDim2.fromOffset(4, 31), UDim2.new(0.45, 0, 0, 34))
local scaleValue = label(content, "100%", 13, UDim2.new(1, -72, 0, 31), UDim2.fromOffset(68, 34), state.accent, Enum.Font.GothamBold)
button(content, "−", UDim2.new(0.48, 0, 0, 32), UDim2.fromOffset(38, 32), function()
    state.scale = math.max(0.7, math.floor((state.scale - 0.1) * 10 + 0.5) / 10)
    scaler.Scale = state.scale
    scaleValue.Text = tostring(math.floor(state.scale * 100)) .. "%"
end)
button(content, "+", UDim2.new(0.48, 44, 0, 32), UDim2.fromOffset(38, 32), function()
    state.scale = math.min(1.2, math.floor((state.scale + 0.1) * 10 + 0.5) / 10)
    scaler.Scale = state.scale
    scaleValue.Text = tostring(math.floor(state.scale * 100)) .. "%"
end)

section("สีเน้น", 82)
local colorChoices = {
    {"เทา", Color3.fromRGB(201, 203, 211)},
    {"ฟ้า", Color3.fromRGB(93, 167, 255)},
    {"เขียว", Color3.fromRGB(91, 210, 155)},
    {"ม่วง", Color3.fromRGB(177, 126, 255)},
}
for i, choice in ipairs(colorChoices) do
    local x = 4 + (i - 1) * 96
    local b = button(content, choice[1], UDim2.fromOffset(x, 111), UDim2.fromOffset(86, 34), function()
        state.accent = choice[2]
        rootStroke.Color = state.accent
        scaleValue.TextColor3 = state.accent
    end)
    b.BackgroundColor3 = choice[2]:Lerp(Color3.fromRGB(24, 24, 28), 0.72)
end

section("การทำงานของหน้าต่าง", 164)
local soundButton
local function refreshSound()
    soundButton.Text = state.sound and "เสียง UI: เปิด" or "เสียง UI: ปิด"
    soundButton.TextColor3 = state.sound and state.accent or Color3.fromRGB(180, 180, 188)
end
soundButton = button(content, "", UDim2.fromOffset(4, 193), UDim2.new(1, -8, 0, 38), function()
    state.sound = not state.sound
    refreshSound()
end)
refreshSound()
label(content, "เสียงนี้มีผลเฉพาะเสียงตอบสนองของปุ่มในหน้าต่างนี้", 11, UDim2.fromOffset(8, 234), UDim2.new(1, -16, 0, 24), Color3.fromRGB(160, 160, 170))

section("ข้อมูล", 275)
local note = label(content, "หน้านี้มีเฉพาะการตั้งค่า UI\nไม่มีระบบเกมหรือการเชื่อมต่อภายนอก\nค่าจะไม่ถูกบันทึกถาวรและรีเซ็ตเมื่อเริ่มใหม่", 12, UDim2.fromOffset(6, 306), UDim2.new(1, -12, 0, 62), Color3.fromRGB(185, 185, 194))
note.TextYAlignment = Enum.TextYAlignment.Top
note.TextWrapped = true
button(content, "รีเซ็ตการตั้งค่า", UDim2.new(1, -150, 1, -42), UDim2.fromOffset(142, 34), function()
    state.scale = 1
    state.sound = true
    state.accent = Color3.fromRGB(201, 203, 211)
    scaler.Scale = state.scale
    rootStroke.Color = state.accent
    scaleValue.Text = "100%"
    scaleValue.TextColor3 = state.accent
    refreshSound()
end)

-- Drag window by header (mouse or touch).
local dragging = false
local dragStart, startPosition
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = root.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

-- Reopen button for the settings window after closing it.
local reopen = make("TextButton", {
    Name = "ReopenSettings",
    Text = "ตั้งค่า",
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(240, 240, 244),
    BackgroundColor3 = Color3.fromRGB(24, 24, 28),
    BorderSizePixel = 0,
    Size = UDim2.fromOffset(76, 34),
    Position = UDim2.new(0, 18, 0.5, -17),
    Visible = false,
}, gui)
Instance.new("UICorner", reopen).CornerRadius = UDim.new(0, 9)
reopen.Activated:Connect(function() root.Visible = true; reopen.Visible = false end)
close.Activated:Connect(function() reopen.Visible = true end)
