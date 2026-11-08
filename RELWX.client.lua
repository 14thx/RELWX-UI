--// ============================================================
--//  RELWX HUB x NEXUS TYPER TOWN | FULL VERSION | PART 1/4
--// ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UIS = UserInputService

-- ฟอนต์ UI
local UI_FONT = "Montserrat"
local function E(name)
    local ok, v = pcall(function() return Enum.Font[name] end)
    return ok and v or Enum.Font.Gotham
end
local FontFamilies = {
    Montserrat = { R = E("Montserrat"), M = E("MontserratMedium"), B = E("MontserratBold") },
    BuilderSans = { R = E("BuilderSans"), M = E("BuilderSansMedium"), B = E("BuilderSansBold") },
    Gotham = { R = Enum.Font.Gotham, M = Enum.Font.GothamMedium, B = Enum.Font.GothamBold },
}
local FNT = FontFamilies[UI_FONT] or FontFamilies.Gotham

local SOUND_ON = "rbxasset://sounds/switch.wav"
local SOUND_OFF = "rbxasset://sounds/button.wav"
local SOUND_FALLBACK = "rbxasset://sounds/electronicpingshort.wav"

-- ==============================================================================
-- 0. ANTI-KICK & ANTI-BAN SHIELD
-- ==============================================================================
pcall(function()
    local lp = Players.LocalPlayer
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if (method == "Kick" or method == "kick") and (self == lp or self == Players) then
                warn("🛡️ [RELWX ANTI-KICK] บล็อกคำสั่ง Kick: " .. tostring(args[1] or "Unknown"))
                return nil
            end
            if method == "FireServer" or method == "InvokeServer" then
                for _, a in ipairs(args) do
                    local str = tostring(a):lower()
                    if str:find("kick") or str:find("anticheat") or str:find("antifall") or str:find("teleport") or str:find("exploit") or str:find("speed") or str:find("fly") then
                        return nil
                    end
                end
            end
            return oldNm(self, ...)
        end))
    end
    if hookfunction and lp and lp.Kick then
        hookfunction(lp.Kick, newcclosure(function(self, ...)
            warn("🛡️ [RELWX ANTI-KICK] บล็อก LocalPlayer:Kick: " .. tostring(({...})[1] or "Unknown"))
            return nil
        end))
    end
end)

-- ==============================================================================
-- 1. GAME VARIABLES & LOCATIONS
-- ==============================================================================
local TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
local LAST_STORED_BOOTH = nil
local isAutoEatEnabled = true
local isAutoCoffeeEnabled = true
local isAutoEatAndDrinkEnabled = true
local VehicleDriveSpeed = 300

local TYPER_LOCATIONS = {
    Bread = { Booth = Vector3.new(872.19, 15.90, 4682.54), Farm = Vector3.new(828.31, 11.21, 4817.85) },
    Catchup = { Booth = Vector3.new(1763.23, 14.23, 4206.70), Farm = Vector3.new(1803.05, 12.65, 4236.79) },
    Pig = { Booth = Vector3.new(306.01, 30.77, -1558.06), Farm = Vector3.new(268.61, 28.74, -1513.65) },
    Mango = { Booth = Vector3.new(-1855.59, 20.06, 586.40), Farm = Vector3.new(-1862.26, 17.33, 535.43) },
    Rice = { Booth = Vector3.new(-92.11, 11.46, 89.48), Farm = Vector3.new(-128.87, 11.02, 78.51) },
    Tomato = { Booth = Vector3.new(-2294.10, 31.28, -1273.91), Farm = Vector3.new(-2319.61, 27.21, -1229.19) },
    Banana = { Booth = Vector3.new(-1528.59, 30.34, -1253.46), Farm = Vector3.new(-1545.12, 28.80, -1126.87) },
    Crab = { Booth = Vector3.new(1442.30, 30.56, 613.34), Farm = Vector3.new(1400.27, 28.69, 648.22) },
    Coconut = { Booth = Vector3.new(-1296.67, 10.37, 4216.59), Farm = Vector3.new(-1333.68, 10.87, 4376.67) },
    Corn = { Booth = Vector3.new(-164.76, 12.39, 4426.24), Farm = Vector3.new(-264.44, 11.95, 4527.12) },
    Egg = { Booth = Vector3.new(-1680.12, 11.39, 4390.69), Farm = Vector3.new(-1799.30, 10.98, 4492.20) },
    Milk = { Booth = Vector3.new(-903.04, 11.41, 4716.36), Farm = Vector3.new(-998.66, 11.23, 4831.62) },
    Sugarcane = { Booth = Vector3.new(-1805.15, 12.98, 3816.89), Farm = Vector3.new(-1922.31, 13.06, 3962.32) },
    Rock = { Booth = Vector3.new(-4163.51, 25.33, -1234.29), Farm = Vector3.new(-4138.03, 29.88, -1286.63), Process = Vector3.new(-935.29, 6.93, 6786.66) },
    Svibranium = { Booth = Vector3.new(2785.16, 30.11, -262.38), Farm = Vector3.new(2723.67, 28.51, -236.17), Process = Vector3.new(-927.35, 6.93, 6763.02) },
    Food = { Crafting = Vector3.new(3442.48, 56.40, 3925.24), BananaProcess = Vector3.new(3429.20, 56.80, 3911.80) },
    Economy = { Market = Vector3.new(-462.0, 18.0, 5324.7) }
}

local FISHING_PARKING_POS = Vector3.new(-902.46, 3.41, 2964.32)
local FISHING_SPOT = Vector3.new(-955.06, -2.65, 2907.18)
local FISHING_LOOK_TARGET = FISHING_SPOT + Vector3.new(-0.25, 0, -0.97) * 20
local BAIT_SHOP_POS = Vector3.new(-949.31, 16.57, 4861.12)
local isAutoFishingEnabled = false
local fishingThread = nil
local fishingPlatform = nil
local isAutoHopOnPlayerNearbyEnabled = true
local autoHopDistance = 60
local isHopping = false
local VehicleHeightOffset = 0
local isVehiclePlatformEnabled = false
local isVehicleNoclipEnabled = true
local vehiclePlatformPart = nil
local MY_SPAWNED_CAR = nil
local isConsumingItem = false
local sessionStart = os.time()

-- ==============================================================================
-- 2. CONFIG & THEME (RELWX UI)
-- ==============================================================================
local CONFIG_FILE = "RELWX_UI_Config.json"
local Defaults = {
    UIAccentColor = "#C9CBD3", UIBackgroundColor = "#0A0A0C", UIButtonColor = "#232328",
    FloatingButtonColor = "#101012", FloatingBorderColor = "#E4E4EA", FloatingGlowColor = "#8E8E98",
    SoundEnabled = true, StatsVisible = true, UIScalePercent = 100, LastTab = "Home",
    WindowVisible = true, Maximized = false, CollapsedSections = "",
    WindowX = 0.5, WindowY = 0.5, FloatX = 0.04, FloatY = 0.25, StatsX = 0.5, StatsY = 0.045,
}
local Config = {}
for k, v in pairs(Defaults) do Config[k] = v end
local LoadedFromFile = false

local function LoadConfig()
    if not (isfile and readfile) then return end
    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not (ok and exists) then return end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(Defaults) do
                if type(data[k]) == type(v) then Config[k] = data[k] end
            end
            LoadedFromFile = true
        end
    end)
end
LoadConfig()
for _, k in ipairs({ "WindowX", "WindowY" }) do Config[k] = math.clamp(Config[k], 0.05, 0.95) end
for _, k in ipairs({ "FloatX", "FloatY", "StatsX", "StatsY" }) do Config[k] = math.clamp(Config[k], 0.02, 0.98) end
Config.UIScalePercent = math.clamp(Config.UIScalePercent, 60, 120)

local SaveHooks = {}
local SaveToken = 0
local function Fire(state) for _, h in ipairs(SaveHooks) do pcall(h, state) end end
local function WriteNow()
    if not writefile then return "unsupported" end
    local ok = pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
    return ok and "saved" or "failed"
end
local function SaveConfig(instant)
    SaveToken = SaveToken + 1
    local token = SaveToken
    Fire("saving")
    local function commit()
        if token ~= SaveToken then return end
        local result = WriteNow()
        Fire(result)
        if result == "saved" then task.delay(1.8, function() if token == SaveToken then Fire("idle") end end) end
    end
    if instant then commit() else task.delay(0.3, commit) end
end
local function SetConfig(key, value)
    if Config[key] == value then return end
    Config[key] = value
    SaveConfig()
end

local function RGB(r, g, b) return Color3.fromRGB(r, g, b) end
local function Lum(c) return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B end
local function Hex(key, fallback)
    local ok, c = pcall(Color3.fromHex, Config[key])
    return ok and c or fallback
end
local Theme = {}
local function ComputeTheme()
    local bg = Hex("UIBackgroundColor", RGB(8, 8, 8))
    local dark = Lum(bg) < 0.5
    local to = dark and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
    Theme.Bg = bg; Theme.Surface = bg:Lerp(to, 0.05); Theme.Surface2 = bg:Lerp(to, 0.095); Theme.Stroke = bg:Lerp(to, 0.17)
    Theme.Text = dark and RGB(244, 244, 244) or RGB(20, 20, 20)
    Theme.Sub = Theme.Text:Lerp(bg, 0.32); Theme.Muted = Theme.Text:Lerp(bg, 0.58)
    Theme.Accent = Hex("UIAccentColor", RGB(190, 190, 190))
    Theme.OnAccent = Lum(Theme.Accent) > 0.55 and RGB(15, 15, 15) or RGB(255, 255, 255)
    Theme.Button = Hex("UIButtonColor", RGB(36, 36, 36))
    local h, s, v = Theme.Accent:ToHSV()
    if s < 0.12 then Theme.Accent2 = Theme.Accent:Lerp(Color3.fromRGB(96, 104, 128), 0.6)
    else Theme.Accent2 = Color3.fromHSV((h + 0.12) % 1, s, math.max(v, 0.6)) end
end
ComputeTheme()
local ThemeHooks = {}
local function OnTheme(fn) ThemeHooks[#ThemeHooks + 1] = fn; pcall(fn) end
local function Bind(obj, prop, key) OnTheme(function() obj[prop] = Theme[key] end) end
local function ApplyTheme() ComputeTheme(); for _, fn in ipairs(ThemeHooks) do pcall(fn) end end

-- ==============================================================================
-- 3. HELPER FUNCTIONS (UI)
-- ==============================================================================
local Orders = setmetatable({}, { __mode = "k" })
local function Next(parent) Orders[parent] = (Orders[parent] or 0) + 1; return Orders[parent] end
local function New(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function Corner(parent, radius) return New("UICorner", { CornerRadius = UDim.new(0, radius) }, parent) end
local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", { Color = color, Thickness = thickness or 1, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end
local function Pad(parent, l, r, t, b)
    return New("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0), PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0) }, parent)
end
local function List(parent, padding) return New("UIListLayout", { Padding = UDim.new(0, padding or 0), SortOrder = Enum.SortOrder.LayoutOrder }, parent) end
local function Text(parent, text, size, font, color, align)
    local l = New("TextLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Text = text or "", TextSize = size or 13, Font = font or FNT.R, TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd }, parent)
    if type(color) == "string" then Bind(l, "TextColor3", color) elseif color then l.TextColor3 = color end
    return l
end
local function Tween(obj, t, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function Apply(obj, animate, props) if animate then Tween(obj, 0.16, props) else for k, v in pairs(props) do obj[k] = v end end end
local function Panel(parent, size, class)
    local f = New(class or "Frame", { BorderSizePixel = 0, LayoutOrder = Next(parent) }, parent)
    if class == "TextButton" then f.Text = ""; f.AutoButtonColor = false end
    if size then f.Size = size end
    Bind(f, "BackgroundColor3", "Surface"); Corner(f, 12); Bind(Stroke(f, Theme.Stroke, 1, 0.4), "Color", "Stroke")
    return f
end
local function HoverRow(btn)
    local st = btn:FindFirstChildOfClass("UIStroke")
    btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface2 }); if st then Tween(st, 0.12, { Transparency = 0.05 }) end end)
    btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface }); if st then Tween(st, 0.12, { Transparency = 0.4 }) end end)
end
local function AccentGrad(parent, rotation)
    local g = New("UIGradient", { Rotation = rotation or 0 }, parent)
    OnTheme(function() g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2) end)
    return g
end
local function Tint(parent)
    local t = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, parent)
    Corner(t, 12)
    local g = AccentGrad(t, 25)
    g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1) })
    return t
end
local function IsPointer(input) return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch end
local function IsMove(input) return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch end

-- ==============================================================================
-- 4. CORE GAME FUNCTIONS (จาก NEXUS HUB)
-- ==============================================================================
local function GrantAntiXGrace(seconds)
    seconds = seconds or 25
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local antiFall = char:FindFirstChild("Antifall") or char:FindFirstChild("AntiFall")
        if antiFall and antiFall:IsA("Script") then antiFall.Disabled = true end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root:SetAttribute("TeleportGrace", os.clock() + seconds)
            root:SetAttribute("AntiFallGrace", os.clock() + seconds)
            root:SetAttribute("VehicleGrace", os.clock() + seconds)
            root:SetAttribute("IgnoreAntiCheat", true)
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end)
end

local function GetGroundLevel(x, z, fallbackY)
    fallbackY = fallbackY or 20
    local rayOrigin = Vector3.new(x, math.max((fallbackY or 20) + 80, 220), z)
    local rayDir = Vector3.new(0, -550, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false
    local filterList = {}
    if LocalPlayer.Character then table.insert(filterList, LocalPlayer.Character) end
    local vehFolder = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vehFolder then table.insert(filterList, vehFolder) end
    if MY_SPAWNED_CAR then table.insert(filterList, MY_SPAWNED_CAR) end
    if vehiclePlatformPart then table.insert(filterList, vehiclePlatformPart) end
    if fishingPlatform then table.insert(filterList, fishingPlatform) end
    params.FilterDescendantsInstances = filterList
    local result = workspace:Raycast(rayOrigin, rayDir, params)
    if result and result.Position then return result.Position.Y end
    return fallbackY
end

local function GetPlayerInventoryCount(itemName)
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local count = pd:GetAttribute(itemName)
        if typeof(count) == "number" then return count end
    end
    return 0
end

local function GetPlayerHunger()
    local stats = LocalPlayer:FindFirstChild("Stats")
    if stats then local hv = stats:GetAttribute("Hunger"); if typeof(hv) == "number" then return hv end end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then local hv = pd:GetAttribute("Hunger") or pd:GetAttribute("Food"); if typeof(hv) == "number" then return hv end end
    return 100
end

local function GetPlayerEnergy()
    local stats = LocalPlayer:FindFirstChild("Stats")
    if stats then local bv = stats:GetAttribute("Brain") or stats:GetAttribute("Energy"); if typeof(bv) == "number" then return bv end end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then local bv = pd:GetAttribute("Brain") or pd:GetAttribute("Energy"); if typeof(bv) == "number" then return bv end end
    return 100
end
--// ============================================================
--//  RELWX HUB x NEXUS TYPER TOWN | FULL VERSION | PART 2/4
--// ============================================================

local function FindAvailableFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local foodCandidates = { "Sushi", "RiceKapaoMoo", "MangoRice", "Rice", "Sandwish", "Burger", "Bread", "Watermelon", "Curry", "Ramen", "Onigiri" }
    for _, food in ipairs(foodCandidates) do
        if pd then local count = pd:GetAttribute(food); if typeof(count) == "number" and count > 0 then return food end end
        if itemFolder and itemFolder:FindFirstChild(food) and itemFolder[food].Value > 0 then return food end
        if bp and bp:FindFirstChild(food) then return food end
        if char and char:FindFirstChild(food) then return food end
    end
    if pd then
        for attr, val in pairs(pd:GetAttributes()) do
            if typeof(val) == "number" and val > 0 then
                local low = attr:lower()
                if low:find("rice") or low:find("khao") or low:find("food") or low:find("kapao") or low:find("sushi") or low:find("sandwich") or low:find("burger") then return attr end
            end
        end
    end
    return nil
end

local function FindAvailableCoffee()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local coffeeCandidates = { "HotCocoa", "Coffee", "HotCoffee", "IcedCoffee", "Cocoa", "OrangeJuice", "Water", "Ice", "Drink" }
    for _, drink in ipairs(coffeeCandidates) do
        if pd then local count = pd:GetAttribute(drink); if typeof(count) == "number" and count > 0 then return drink end end
        if itemFolder and itemFolder:FindFirstChild(drink) and itemFolder[drink].Value > 0 then return drink end
        if bp and bp:FindFirstChild(drink) then return drink end
        if char and char:FindFirstChild(drink) then return drink end
    end
    if pd then
        for attr, val in pairs(pd:GetAttributes()) do
            if typeof(val) == "number" and val > 0 then
                local low = attr:lower()
                if low:find("cocoa") or low:find("coffee") or low:find("cafe") or low:find("tea") or low:find("drink") or low:find("water") or low:find("hotcocoa") then return attr end
            end
        end
    end
    return nil
end

local function UseItem(itemName)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_inventory", "Use", itemName)
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_inventory") then rem._inventory:FireServer("Use", itemName) end
        end
    end)
end

local function ConsumeItemSafely(itemName, isFood, customWait)
    if isConsumingItem or not itemName then return end
    isConsumingItem = true
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        pcall(function()
            local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
            if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_inventory", "Use", itemName) else UseItem(itemName) end
        end)
        local tool = nil
        local t0 = os.clock()
        while os.clock() - t0 < 2.5 do
            char = LocalPlayer.Character
            tool = char and char:FindFirstChild(itemName)
            if not tool and LocalPlayer:FindFirstChild("Backpack") then
                tool = LocalPlayer.Backpack:FindFirstChild(itemName)
                if tool and hum then hum:EquipTool(tool) end
            end
            if tool and tool.Parent == char then break end
            task.wait(0.1)
        end
        if tool and char then
            hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if tool.Parent ~= char then hum:EquipTool(tool); task.wait(0.25) end
                task.wait(0.3)
                pcall(function()
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendMouseButtonEvent(500, 500, 0, true, game, 0)
                    task.wait(0.08)
                    vim:SendMouseButtonEvent(500, 500, 0, false, game, 0)
                end)
                pcall(function() tool:Activate() end)
                local waitDuration = customWait or 5.5
                local waitStart = os.clock()
                while os.clock() - waitStart < waitDuration do task.wait(0.2) end
                task.wait(0.3)
                pcall(function() hum:UnequipTools() end)
            end
        else task.wait(1.5) end
    end)
    isConsumingItem = false
end

local function AutoEatThenDrink(targetPercent)
    targetPercent = targetPercent or 95
    if isConsumingItem then return end
    local loopCount = 0
    while loopCount < 8 do
        local hunger = GetPlayerHunger()
        local brain = GetPlayerEnergy()
        if (hunger and hunger >= targetPercent) and (brain and brain >= targetPercent) then break end
        local food = FindAvailableFood()
        local drink = FindAvailableCoffee()
        if food and (hunger == nil or hunger < targetPercent) then ConsumeItemSafely(food, true, 5.5); task.wait(0.4); hunger = GetPlayerHunger() end
        if drink and (brain == nil or brain < targetPercent) then ConsumeItemSafely(drink, false, 5.5); task.wait(0.4); brain = GetPlayerEnergy() end
        if (not food or (hunger and hunger >= targetPercent)) and (not drink or (brain and brain >= targetPercent)) then break end
        loopCount = loopCount + 1; task.wait(0.3)
    end
end

local function CheckAndAutoEat()
    if not isAutoEatAndDrinkEnabled or isConsumingItem then return end
    local hunger = GetPlayerHunger()
    local brain = GetPlayerEnergy()
    if (hunger and hunger <= 80) or (brain and brain <= 80) then AutoEatThenDrink(95) end
end

local function CancelGameFarm()
    pcall(function()
        local af = PlayerGui:FindFirstChild("Auto Farm") or PlayerGui:FindFirstChild("AutoFarm")
        if af then
            local closeBtn = af:FindFirstChild("Close", true)
            if closeBtn then ClickGuiButton(closeBtn) end
            af.Enabled = false
        end
    end)
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
    end)
    task.wait(0.3)
end

-- [ฟังก์ชันยานพาหนะ]
local function IsMyVehicle(v)
    if not v or not v:IsA("Model") or not v.Parent then return false end
    if MY_SPAWNED_CAR and v == MY_SPAWNED_CAR then return true end
    local myName = LocalPlayer.Name
    local myUserId = LocalPlayer.UserId
    local owner = v:GetAttribute("Owner") or v:GetAttribute("OwnerName") or v:GetAttribute("Player")
    local ownerId = v:GetAttribute("OwnerId") or v:GetAttribute("UserId") or v:GetAttribute("PlayerId")
    if owner ~= nil and tostring(owner) ~= "" then
        if tostring(owner) == myName or tostring(owner) == tostring(myUserId) then return true else return false end
    end
    if ownerId ~= nil and tonumber(ownerId) then
        if tonumber(ownerId) == myUserId then return true else return false end
    end
    local ownerVal = v:FindFirstChild("Owner") or v:FindFirstChild("Player")
    if ownerVal and (ownerVal:IsA("StringValue") or ownerVal:IsA("ObjectValue")) then
        if ownerVal.Value == myName or ownerVal.Value == LocalPlayer then return true else return false end
    end
    return false
end

local function GetPlayerVehicle()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local veh = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if veh and IsMyVehicle(veh) then return veh end
    end
    if MY_SPAWNED_CAR and MY_SPAWNED_CAR.Parent and MY_SPAWNED_CAR.PrimaryPart and IsMyVehicle(MY_SPAWNED_CAR) then return MY_SPAWNED_CAR end
    local vehFolder = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    if vehFolder then
        for _, v in ipairs(vehFolder:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then MY_SPAWNED_CAR = v; return v end
        end
    end
    return nil
end

local function GetNearbyPlayerVehicle(maxDist)
    maxDist = maxDist or 80
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge, nil end
    if hum and hum.Sit and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        local veh = hum.SeatPart:FindFirstAncestorOfClass("Model")
        if veh and IsMyVehicle(veh) then return veh, 0, nil end
    end
    local vehFolder = (workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Vehicles")) or workspace:FindFirstChild("Vehicles")
    local nearestCar = nil; local minDist = math.huge
    if vehFolder then
        for _, v in ipairs(vehFolder:GetChildren()) do
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then
                local dist = (v.PrimaryPart.Position - root.Position).Magnitude
                if dist < minDist then minDist = dist; nearestCar = v end
            end
        end
    end
    if nearestCar then
        if minDist <= maxDist then MY_SPAWNED_CAR = nearestCar; return nearestCar, minDist, nil
        else return nil, minDist, nearestCar end
    end
    return nil, math.huge, nil
end

local function PressFToEnterCar(car)
    if not car or not car.Parent or not IsMyVehicle(car) then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    local seat = car:FindFirstChild("DriveSeat", true) or car:FindFirstChildWhichIsA("VehicleSeat", true) or car:FindFirstChildWhichIsA("Seat", true)
    if not seat then return false end
    if hum.Sit and hum.SeatPart == seat then MY_SPAWNED_CAR = car; return true end
    if hum.Sit and hum.SeatPart ~= seat then hum.Sit = false; task.wait(0.2) end
    GrantAntiXGrace(20)
    local drivePrompt = nil
    local pFolder = seat:FindFirstChild("Prompt")
    if pFolder and pFolder:FindFirstChild("Prompt") and pFolder.Prompt:IsA("ProximityPrompt") then drivePrompt = pFolder.Prompt
    else
        for _, d in ipairs(seat:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.ActionText:lower():find("drive") then drivePrompt = d; break end
        end
    end
    if not drivePrompt then
        for _, d in ipairs(car:GetDescendants()) do
            if d:IsA("ProximityPrompt") and (d.ActionText:lower():find("drive") or d.Name:lower():find("drive")) then drivePrompt = d; break end
        end
    end
    if drivePrompt then
        pcall(function() drivePrompt.HoldDuration = 0 end)
        pcall(function() fireproximityprompt(drivePrompt) end)
        pcall(function() drivePrompt:InputHoldBegin(); task.wait(0.08); drivePrompt:InputHoldEnd() end)
    end
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.06)
        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
    task.wait(0.2)
    if not (hum.Sit and hum.SeatPart) then
        pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.5, 0); seat:Sit(hum) end)
        task.wait(0.2)
    end
    return (hum.Sit and hum.SeatPart ~= nil)
end

local function EnsurePlayerSeatedInCar(car) return PressFToEnterCar(car) end

local function ExitCarNaturally(car)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum.Sit then hum.Sit = false; task.wait(0.12) end
    if car and car.PrimaryPart then
        local rightVec = car.PrimaryPart.CFrame.RightVector
        local exitPos = car.PrimaryPart.Position - (rightVec * 4.2)
        local groundY = GetGroundLevel(exitPos.X, exitPos.Z, car.PrimaryPart.Position.Y)
        root.CFrame = CFrame.new(exitPos.X, groundY + 1.8, exitPos.Z)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(0.15)
end

local function SmoothWalkTo(targetPos, maxTimeout, shouldContinueCheck, stopDist)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    maxTimeout = maxTimeout or 50; stopDist = stopDist or 2.5
    local startTime = os.clock(); local lastPos = root.Position; local stuckTicks = 0
    while (root.Position - targetPos).Magnitude > stopDist and (os.clock() - startTime < maxTimeout) do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(5)
        hum:MoveTo(targetPos)
        if (root.Position - lastPos).Magnitude < 0.4 then
            stuckTicks = stuckTicks + 1
            if stuckTicks >= 3 then hum.Jump = true; stuckTicks = 0 end
        else stuckTicks = 0 end
        lastPos = root.Position; task.wait(0.15)
    end
    return (root.Position - targetPos).Magnitude <= 10
end

local function DriveCarTo(destination, shouldContinueCheck)
    local myCar = GetNearbyPlayerVehicle(80)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not myCar or not IsMyVehicle(myCar) then myCar = GetPlayerVehicle() end
    if not myCar or not hum or not root then return false end
    local seat = myCar:FindFirstChildWhichIsA("VehicleSeat", true)
    if not seat then return false end
    EnsurePlayerSeatedInCar(myCar); task.wait(0.1)
    local currentPos = seat.Position; local startY = currentPos.Y
    local initialGround = GetGroundLevel(currentPos.X, currentPos.Z, startY)
    local naturalRideHeight = math.clamp(startY - initialGround, 2.3, 3.2)
    local distTotal = (Vector2.new(destination.X, destination.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude
    if distTotal < 5 then return true end
    local traveled = 0; local lastTick = os.clock()
    while traveled < distTotal do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(15)
        if not hum.Sit or hum.SeatPart ~= seat then pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.8, 0); seat:Sit(hum) end) end
        local currentSpeed = tonumber(VehicleDriveSpeed) or 200; currentSpeed = math.clamp(currentSpeed, 10, 500)
        local now = os.clock(); local dt = math.min(now - lastTick, 0.1); lastTick = now
        traveled = math.min(distTotal, traveled + (currentSpeed * dt))
        local alpha = math.clamp(traveled / distTotal, 0, 1)
        local targetX = currentPos.X + (destination.X - currentPos.X) * alpha
        local targetZ = currentPos.Z + (destination.Z - currentPos.Z) * alpha
        local estY = currentPos.Y + (destination.Y - currentPos.Y) * alpha
        local groundY = GetGroundLevel(targetX, targetZ, estY)
        local naturalH = naturalRideHeight or 2.4; local surfaceY = groundY + naturalH
        local dir = Vector3.new(destination.X - targetX, 0, destination.Z - targetZ)
        local lookCFrame = CFrame.new(targetX, surfaceY, targetZ)
        if dir.Magnitude > 0.1 then lookCFrame = CFrame.lookAt(Vector3.new(targetX, surfaceY, targetZ), Vector3.new(targetX, surfaceY, targetZ) + dir) end
        myCar:PivotTo(lookCFrame); RunService.Heartbeat:Wait()
    end
    local endGround = GetGroundLevel(destination.X, destination.Z, destination.Y)
    local targetEndY = (destination.Y < 5.0 and (destination.Y + naturalRideHeight)) or math.max(endGround + naturalRideHeight, 6.0)
    myCar:PivotTo(CFrame.new(destination.X, targetEndY, destination.Z)); task.wait(0.1); return true
end

local function GetNearestCarBooth(fromPos)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or TOWN_CAR_SPAWN
    local closestPos = nil; local closestDist = math.huge
    for cropName, data in pairs(TYPER_LOCATIONS) do
        if data and data.Booth then local d = (data.Booth - fromPos).Magnitude; if d < closestDist then closestDist = d; closestPos = data.Booth end end
    end
    return closestPos or TOWN_CAR_SPAWN
end

local function FindBoothPromptNear(fromPos, maxDist)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position)
    if not fromPos then return nil end
    maxDist = maxDist or 30
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, cropFolder in ipairs(farmSys:GetChildren()) do
            local promptFolder = cropFolder:FindFirstChild("Prompt")
            local spawnFolder = promptFolder and promptFolder:FindFirstChild("Spawn")
            if spawnFolder then
                local pr = spawnFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pr then
                    local p = pr.Parent
                    local pos = (p:IsA("Attachment") and p.WorldPosition) or (p:IsA("BasePart") and p.Position)
                    if pos and (pos - fromPos).Magnitude <= maxDist then return pr end
                end
            end
        end
    end
    return nil
end

local function FindPromptNear(centerPos, maxDist, matchKeyword)
    maxDist = maxDist or 25
    local closest, closestDist = nil, maxDist
    local systems = workspace:FindFirstChild("Systems")
    local containers = systems and {systems} or {workspace}
    for _, container in ipairs(containers) do
        for _, prompt in ipairs(container:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local pPart = prompt.Parent
                local pPos = pPart and (pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Attachment") and pPart.WorldPosition))
                if pPos then
                    local d = (pPos - centerPos).Magnitude
                    if d <= closestDist then
                        if not matchKeyword or string.find(string.lower(prompt.ActionText or ""), string.lower(matchKeyword)) then closest = prompt; closestDist = d end
                    end
                end
            end
        end
    end
    return closest
end

local function ClickGuiButton(btn)
    if not btn then return end
    pcall(function()
        if getconnections then for _, con in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() if con.Function then con.Function() end end) end end
        if firesignal then pcall(function() firesignal(btn.MouseButton1Click) end) end
    end)
end

local function SafeClickGuiButton(btn)
    if not btn or not btn:IsA("GuiButton") then return end
    pcall(function() if firesignal then pcall(function() firesignal(btn.MouseButton1Click) end) end end)
end

local function TriggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    pcall(function()
        if fireproximityprompt then pcall(function() fireproximityprompt(prompt) end) end
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration > 0 and (prompt.HoldDuration + 0.05) or 0.1)
            prompt:InputHoldEnd()
        end)
    end)
end
--// ============================================================
--//  RELWX HUB x NEXUS TYPER TOWN | FULL VERSION | PART 3/4
--// ============================================================

local function GetSpawnPointForBooth(boothPos)
    local bestPt = nil; local bestDist = math.huge
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, farm in ipairs(farmSys:GetChildren()) do
            local sp = farm:FindFirstChild("Prompt") and farm.Prompt:FindFirstChild("Spawn")
            local ptFolder = sp and sp:FindFirstChild("Point")
            if ptFolder then
                for _, pt in ipairs(ptFolder:GetChildren()) do
                    if pt:IsA("BasePart") then local d = (pt.Position - boothPos).Magnitude; if d < bestDist then bestDist = d; bestPt = pt end end
                end
            end
        end
    end
    return bestPt
end

local function StoreCarAtBooth(boothPos)
    GrantAntiXGrace(35)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myCar = GetPlayerVehicle()
    if not myCar then return end
    local carName = myCar.Name or "Buggy"
    local spPt = GetSpawnPointForBooth(boothPos)
    if myCar.PrimaryPart then
        if spPt and spPt:IsA("BasePart") then myCar:PivotTo(spPt.CFrame + Vector3.new(0, 1.2, 0))
        else local groundY = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y); myCar:PivotTo(CFrame.new(boothPos.X, groundY + 1.2, boothPos.Z)) end
        myCar.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
        myCar.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(2.0); ExitCarNaturally(myCar)
    if root and (root.Position - boothPos).Magnitude > 8 then SmoothWalkTo(boothPos, 3, nil, 5.0) end
    local boothPrompt = FindBoothPromptNear(boothPos, 40)
    if boothPrompt then boothPrompt.Enabled = true; TriggerPrompt(boothPrompt) end
    local cs = PlayerGui:WaitForChild("Car_Spawn", 1.5)
    local t0 = os.clock()
    while (not cs or not cs:FindFirstChild("Group") or not cs.Group.Visible) and (os.clock() - t0 < 1.2) do
        if boothPrompt then TriggerPrompt(boothPrompt) end; task.wait(0.15)
    end
    if cs and cs:FindFirstChild("Group") and cs.Group.Visible then
        local btn = cs.Group:FindFirstChild("Pound", true)
        if btn and btn:IsA("GuiButton") then ClickGuiButton(btn) end
    end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_carspawn", "Despawn", carName); MY_SPAWNED_CAR = nil end
    end)
end

local function SpawnCarAtBooth(boothPos)
    GrantAntiXGrace(40)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil end
    if boothPos then
        local distToBooth = (root.Position - boothPos).Magnitude
        if distToBooth > 15 then
            local groundY = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
            root.CFrame = CFrame.new(boothPos.X, groundY + 1.2, boothPos.Z)
            root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero; task.wait(0.2)
        else root.CFrame = CFrame.lookAt(root.Position, Vector3.new(boothPos.X, root.Position.Y, boothPos.Z)) end
    end
    local boothPrompt = FindBoothPromptNear(root.Position, 30) or (boothPos and FindBoothPromptNear(boothPos, 30))
    if boothPrompt then boothPrompt.Enabled = true; TriggerPrompt(boothPrompt) end
    local cs = PlayerGui:FindFirstChild("Car_Spawn")
    local group = cs and cs:FindFirstChild("Group")
    local tOpen = os.clock()
    while os.clock() - tOpen < 3.0 do
        if group and group.Visible then break end
        if boothPrompt then TriggerPrompt(boothPrompt) end
        task.wait(0.1)
        cs = PlayerGui:FindFirstChild("Car_Spawn"); group = cs and cs:FindFirstChild("Group")
    end
    if group and group.Visible then
        local spawnBtn = group:FindFirstChild("Spawn", true) or group:FindFirstChild("Buggy", true)
        if spawnBtn and spawnBtn:IsA("GuiButton") then ClickGuiButton(spawnBtn) end
        task.wait(1.0)
        local finalCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
        if finalCar then MY_SPAWNED_CAR = finalCar; EnsurePlayerSeatedInCar(finalCar); if cs and cs:FindFirstChild("Group") then cs.Group.Visible = false end; return finalCar end
    end
    return nil
end

local function WarpToTownAndSpawnCar()
    GrantAntiXGrace(45)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    if hum and hum.Sit then hum.Sit = false; task.wait(0.15) end
    local groundY = GetGroundLevel(TOWN_CAR_SPAWN.X, TOWN_CAR_SPAWN.Z, TOWN_CAR_SPAWN.Y)
    root.CFrame = CFrame.new(Vector3.new(TOWN_CAR_SPAWN.X, groundY + 1.2, TOWN_CAR_SPAWN.Z))
    root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero; task.wait(0.4)
    local car = SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if car then EnsurePlayerSeatedInCar(car) end
    return car
end

local function EnsureCarAvailable(boothPos)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetBooth = boothPos or (root and GetNearestCarBooth(root.Position)) or TOWN_CAR_SPAWN
    local nearbyCar = GetNearbyPlayerVehicle(80)
    if nearbyCar and nearbyCar.PrimaryPart and IsMyVehicle(nearbyCar) then EnsurePlayerSeatedInCar(nearbyCar); return nearbyCar end
    local car = SpawnCarAtBooth(targetBooth)
    if car and IsMyVehicle(car) then EnsurePlayerSeatedInCar(car) end
    return car
end

local function GetExactFarmPromptPosition(cropName)
    local locData = TYPER_LOCATIONS[cropName]
    local fallbackPos = locData and locData.Farm
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local farmFolder = farmSys and farmSys:FindFirstChild(cropName)
    if farmFolder then
        for _, desc in ipairs(farmFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local prParent = desc.Parent
                local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition) or (prParent:IsA("BasePart") and prParent.Position)
                if pPos then return pPos end
            end
        end
    end
    return fallbackPos
end

local function GetHumanLikeFarmStandingSpot(centerPos)
    local farmRadius = 3.8
    local occupiedAngles = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local d = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(centerPos.X, 0, centerPos.Z)).Magnitude
            if d <= 10 then table.insert(occupiedAngles, math.atan2(hrp.Position.Z - centerPos.Z, hrp.Position.X - centerPos.X)) end
        end
    end
    local bestAngle = nil; local maxMinDist = -1
    for i = 0, 15 do
        local testAngle = (i / 16) * math.pi * 2
        local minDiff = math.pi
        for _, occAngle in ipairs(occupiedAngles) do
            local diff = math.abs(testAngle - occAngle); if diff > math.pi then diff = (math.pi * 2) - diff end
            if diff < minDiff then minDiff = diff end
        end
        if minDiff > maxMinDist then maxMinDist = minDiff; bestAngle = testAngle end
    end
    if not bestAngle then bestAngle = math.random() * math.pi * 2 end
    local standX = centerPos.X + math.cos(bestAngle) * farmRadius
    local standZ = centerPos.Z + math.sin(bestAngle) * farmRadius
    local groundY = GetGroundLevel(standX, standZ, centerPos.Y)
    return Vector3.new(standX, groundY + 2.2, standZ), bestAngle
end

local function TriggerFarmPromptDirectly(cropName)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    local farmFolder = farmSys and farmSys:FindFirstChild(cropName)
    local targetPrompt = nil
    if farmFolder then
        for _, desc in ipairs(farmFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then targetPrompt = desc; break end
        end
    end
    if not targetPrompt and farmSys then
        for _, prompt in ipairs(farmSys:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local prParent = prompt.Parent
                local pPos = (prParent:IsA("Attachment") and prParent.WorldPosition) or (prParent:IsA("BasePart") and prParent.Position)
                if pPos and (pPos - root.Position).Magnitude <= 20 then
                    local action = (prompt.ActionText or ""):lower()
                    if not action:find("spawn") and not action:find("car") then targetPrompt = prompt; break end
                end
            end
        end
    end
    if targetPrompt then
        local holdTime = math.max((targetPrompt.HoldDuration or 0.1), 0.15) + 0.12
        pcall(function() targetPrompt:InputHoldBegin() end); task.wait(holdTime); pcall(function() targetPrompt:InputHoldEnd() end)
        return true
    end
    return false
end

local function HarvestSingleCrop(cropName, targetAmount, shouldContinueCheck)
    targetAmount = 60
    local curCount = GetPlayerInventoryCount(cropName)
    if curCount >= targetAmount then return end
    local locData = TYPER_LOCATIONS[cropName]
    if not locData then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetNearbyPlayerVehicle(80)
    if not myCar or not hum.Sit then
        if myCar then EnsurePlayerSeatedInCar(myCar) else myCar = EnsureCarAvailable(locData and locData.Booth) end
    end
    local farmPos = locData.Farm
    local exactCenter = GetExactFarmPromptPosition(cropName) or farmPos
    local farmParkingPos = Vector3.new(exactCenter.X + 4.5, GetGroundLevel(exactCenter.X + 4.5, exactCenter.Z + 4.5, exactCenter.Y), exactCenter.Z + 4.5)
    DriveCarTo(farmParkingPos, shouldContinueCheck); task.wait(2.0)
    ExitCarNaturally(myCar); task.wait(0.3)
    local standPos, bestAngle = GetHumanLikeFarmStandingSpot(exactCenter)
    SmoothWalkTo(standPos, 6, shouldContinueCheck, 1.2); task.wait(0.2)
    if root then
        local finalGround = GetGroundLevel(standPos.X, standPos.Z, exactCenter.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, finalGround + 2.2, standPos.Z), Vector3.new(exactCenter.X, finalGround + 2.2, exactCenter.Z))
        root.AssemblyLinearVelocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(1.5)
    TriggerFarmPromptDirectly(cropName); task.wait(1.5)
    local isFarming = false
    local afGui = PlayerGui:FindFirstChild("Auto Farm") or PlayerGui:FindFirstChild("AutoFarm")
    if afGui and ((afGui:FindFirstChild("Group") and afGui.Group.Visible) or afGui.Enabled) then isFarming = true end
    if not isFarming and GetPlayerInventoryCount(cropName) == curCount then task.wait(0.5); TriggerFarmPromptDirectly(cropName); task.wait(1.5) end
    local farmTimeout = os.clock()
    while curCount < targetAmount do
        if isAutoEatAndDrinkEnabled and not isConsumingItem then
            local h = GetPlayerHunger(); local e = GetPlayerEnergy()
            if (h and h <= 75) or (e and e <= 75) then
                CancelGameFarm(); task.wait(0.3)
                if h and h <= 75 then CheckAndAutoEat() end
                if e and e <= 75 then CheckAndAutoEat() end
                task.wait(0.3); TriggerFarmPromptDirectly(cropName); task.wait(1.2); farmTimeout = os.clock()
            end
        end
        if shouldContinueCheck and not shouldContinueCheck() then break end
        if os.clock() - farmTimeout > 180 then break end
        GrantAntiXGrace(15)
        local newCount = GetPlayerInventoryCount(cropName)
        if newCount > curCount then curCount = newCount; farmTimeout = os.clock()
        elseif (os.clock() - farmTimeout > 15) and (newCount == curCount) then TriggerFarmPromptDirectly(cropName); farmTimeout = os.clock() end
        task.wait(0.5)
    end
    local targetBooth = (locData and locData.Booth) or GetNearestCarBooth(root.Position)
    if targetBooth then SmoothWalkTo(targetBooth, 45, shouldContinueCheck, 5.5); task.wait(0.3) end
    local car = SpawnCarAtBooth(targetBooth)
    if not car then car = EnsureCarAvailable(targetBooth) end
    if car then EnsurePlayerSeatedInCar(car) end
    task.wait(0.3)
end

-- [ฟังก์ชันคราฟ]
local function GetCraft3Prompt()
    local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
    if c3 then
        local p = c3:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p and p.Enabled then return p end
    end
    return nil
end

local function CraftFoodAtStation(recipeName, shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable() end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process"); if procGui and procGui:FindFirstChild("Group") then procGui.Group.Visible = false end
        local ecoGui = PlayerGui:FindFirstChild("Economy"); if ecoGui and ecoGui:FindFirstChild("Group") then ecoGui.Group.Visible = false end
    end)
    local cPrompt = GetCraft3Prompt()
    local exactCraftPos = nil
    if cPrompt then
        local pParent = cPrompt.Parent
        exactCraftPos = (pParent:IsA("BasePart") and pParent.Position) or (pParent:IsA("Attachment") and pParent.WorldPosition)
    end
    exactCraftPos = exactCraftPos or foodData.Crafting
    DriveCarTo(exactCraftPos + Vector3.new(0, 0, 5.0), shouldContinueCheck); task.wait(0.2)
    if hum.Sit then hum.Sit = false; task.wait(0.2) end
    local groundY = GetGroundLevel(exactCraftPos.X, exactCraftPos.Z, exactCraftPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(exactCraftPos.X, groundY + 3.0, exactCraftPos.Z + 2.5), exactCraftPos)
    task.wait(0.15)
    if cPrompt then TriggerPrompt(cPrompt) end
    local cg = PlayerGui:WaitForChild("Crafting", 4)
    local tWaitUI = os.clock()
    while os.clock() - tWaitUI < 3.0 do
        if cg and cg:FindFirstChild("Group") and cg.Group.Visible then break end
        if cPrompt then TriggerPrompt(cPrompt) end
        task.wait(0.3)
    end
    local function GetMaxCraftAmount()
        local b, c, p, m, r = GetPlayerInventoryCount("Bread"), GetPlayerInventoryCount("Catchup"), GetPlayerInventoryCount("Pig"), GetPlayerInventoryCount("Mango"), GetPlayerInventoryCount("Rice")
        if recipeName == "Sandwish" then return math.min(math.floor(b/3), math.floor(c/2), math.floor(p/2)) end
        if recipeName == "MangoRice" then return math.min(math.floor(m/2), math.floor(r/3)) end
        if recipeName == "RiceKapaoMoo" then return math.min(math.floor(p/2), math.floor(r/3)) end
        return 1
    end
    local toCraft = GetMaxCraftAmount()
    if toCraft > 0 then
        local mainFrame = cg and cg:FindFirstChild("Group") and cg.Group:FindFirstChild("Main")
        if mainFrame then
            local scroller = mainFrame:FindFirstChild("Left_Tab") and mainFrame.Left_Tab:FindFirstChild("ScrollingFrame")
            if scroller then
                local sandCatBtn = scroller:FindFirstChild("Sand") or scroller:FindFirstChild("Food")
                if sandCatBtn then SafeClickGuiButton(sandCatBtn); task.wait(0.2) end
                local recipeBtn = scroller:FindFirstChild(recipeName) or mainFrame:FindFirstChild(recipeName, true)
                if recipeBtn then SafeClickGuiButton(recipeBtn); task.wait(0.2) end
            end
            local amtBox = mainFrame:FindFirstChild("Function") and mainFrame.Function:FindFirstChild("Amount") and mainFrame.Function.Amount:FindFirstChild("Amount")
            if amtBox and amtBox:IsA("TextBox") then amtBox.Text = tostring(toCraft); task.wait(0.1) end
            local craftBtn = mainFrame:FindFirstChild("Button") and mainFrame.Button:FindFirstChild("Craft")
            if craftBtn then SafeClickGuiButton(craftBtn) end
        end
        pcall(function()
            local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
            if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_crafting", "Request", "Craft_3", recipeName, toCraft, false) end
        end)
        local tStart = os.clock()
        while (os.clock() - tStart < 10.0) do if shouldContinueCheck and not shouldContinueCheck() then break end; task.wait(0.5) end
        pcall(function()
            local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
            if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_crafting", "Complete", "Craft_3", recipeName, toCraft, false) end
        end)
    end
    task.wait(0.3)
    pcall(function() if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end end)
    task.wait(3.0)
    local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar2 then EnsurePlayerSeatedInCar(myCar2) end
end

local function ProcessOreAtStation(oreName, requiredMin, shouldContinueCheck)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local locData = TYPER_LOCATIONS[oreName]
    local exactProcPos = (locData and locData.Process) or Vector3.new(-935.29, 6.93, 6786.66)
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then myCar = EnsureCarAvailable() end
    if myCar then EnsurePlayerSeatedInCar(myCar) end
    DriveCarTo(exactProcPos + Vector3.new(0, 0, 5.0), shouldContinueCheck); task.wait(0.1)
    if hum.Sit then hum.Sit = false; task.wait(0.1) end
    local groundY = GetGroundLevel(exactProcPos.X, exactProcPos.Z, exactProcPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(exactProcPos.X, groundY + 3.0, exactProcPos.Z + 2.5), exactProcPos); task.wait(0.1)
    local pFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild(oreName)
    local procPrompt = pFolder and pFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
    if procPrompt then TriggerPrompt(procPrompt) end; task.wait(0.3)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_process", "Start", oreName) end
    end)
    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then
            local mainFrame = procGui.Group:FindFirstChild("Main")
            local actionBtn = mainFrame and mainFrame:FindFirstChild("ActionBtn")
            if actionBtn and firesignal then firesignal(actionBtn.MouseButton1Click) end
        end
    end)
    requiredMin = requiredMin or (oreName == "Svibranium" and 4 or 2)
    local tProc = os.clock()
    while (GetPlayerInventoryCount(oreName) >= requiredMin) and (os.clock() - tProc < 180) do
        if shouldContinueCheck and not shouldContinueCheck() then break end; task.wait(3.2)
    end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_process", "Stop") end
    end)
    task.wait(3.0)
    local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(Vector3.new(-876.62, 10.52, 6662.98))
    if myCar2 then EnsurePlayerSeatedInCar(myCar2) end
end

local function DepositAllToVault(shouldContinueCheck)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local VAULT_COORDS = Vector3.new(-1.98, 26.54, 8632.61)
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then EnsureCarAvailable() end
    DriveCarTo(VAULT_COORDS + Vector3.new(0, 0, 8.0), shouldContinueCheck); task.wait(0.2)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            local pData = LocalPlayer:FindFirstChild("PlayerData")
            if pData then
                for attrName, _ in pairs(pData:GetAttributes()) do
                    local count = GetPlayerInventoryCount(attrName)
                    if count > 0 then pcall(function() Remotes_m.Invoke("_vault_tx", "Deposit", attrName, count) end); task.wait(0.15) end
                end
            end
        end
    end)
    task.wait(0.3)
    local carAfterVault = GetPlayerVehicle() or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if carAfterVault then EnsurePlayerSeatedInCar(carAfterVault) end
end

local function SellAtEconomyMarket(shouldContinueCheck)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    local marketPos = TYPER_LOCATIONS.Economy.Market
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then
        if not myCar then myCar = EnsureCarAvailable(TOWN_CAR_SPAWN) end
        if myCar then EnsurePlayerSeatedInCar(myCar) end
    end
    DriveCarTo(marketPos, shouldContinueCheck); task.wait(0.3)
    ExitCarNaturally(myCar)
    if root then
        local gY = GetGroundLevel(marketPos.X, marketPos.Z, marketPos.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(marketPos.X + 2.5, gY + 2.2, marketPos.Z), marketPos)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.2)
    local econPrompt = FindPromptNear(root.Position, 25, "econ")
    if econPrompt then TriggerPrompt(econPrompt) end; task.wait(0.4)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then local Remotes_m = require(remCore); Remotes_m.Invoke("_economy", "SellAll"); Remotes_m.Fire("_economy", "SellAll") end
    end)
    task.wait(1.0)
    pcall(function() local eg = PlayerGui:FindFirstChild("Economy"); if eg and eg:FindFirstChild("Group") then eg.Group.Visible = false end end)
end

-- [ฟังก์ชันตกปลา - ย่อ]
local function StartAutoFishing()
    isAutoFishingEnabled = true
    warn("🎣 เริ่มตกปลาอัตโนมัติ (Placeholder)")
end
local function StopAutoFishing()
    isAutoFishingEnabled = false
    warn("🛑 หยุดตกปลา")
end
--// ============================================================
--//  RELWX HUB x NEXUS TYPER TOWN | FULL VERSION | PART 4/4
--// ============================================================

pcall(function()
    for _, v in ipairs(PlayerGui:GetChildren()) do
        if v.Name == "RELWX_UI" or v.Name == "RELWX_Floating" or v.Name == "RELWX_Stats" then v:Destroy() end
    end
end)

local Screen = New("ScreenGui", { Name = "RELWX_UI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999998, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
local Conns = {}
local function Track(c) Conns[#Conns + 1] = c; return c end
Screen.Destroying:Connect(function() for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end end)

local BW, BH = 740, 580
local SW = 172

local function ViewSize()
    local s = Screen.AbsoluteSize
    if s.X > 0 and s.Y > 0 then return s end
    return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
end
local function TargetScale()
    local v = ViewSize()
    local fit = math.min(v.X * 0.97 / BW, v.Y * 0.95 / BH)
    local base = math.min(fit * (Config.Maximized and 1 or 0.92), Config.Maximized and 1.4 or 1.1)
    local s = base * (Config.UIScalePercent / 100)
    return math.clamp(s, 0.3, math.max(0.3, fit))
end

local Main = New("CanvasGroup", { Name = "Main", Size = UDim2.fromOffset(BW, BH), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(Config.WindowX, Config.WindowY), BorderSizePixel = 0, BackgroundTransparency = 0.04, GroupTransparency = 1, Active = true, Visible = false }, Screen)
Bind(Main, "BackgroundColor3", "Bg")
Corner(Main, 18)

local function Aurora(key, rot)
    local f = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, Main)
    Bind(f, "BackgroundColor3", key)
    Corner(f, 18)
    New("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }) }, f)
end
Aurora("Accent", 35); Aurora("Accent2", 215)

local Dust = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true }, Main)
for i = 1, 16 do
    local sz = math.random(2, 4); local x = math.random()
    local p = New("Frame", { Size = UDim2.fromOffset(sz, sz), Position = UDim2.fromScale(x, 1.05), BorderSizePixel = 0, BackgroundTransparency = 0.55 + math.random() * 0.3 }, Dust)
    Corner(p, 2); Bind(p, "BackgroundColor3", (i % 2 == 0) and "Accent" or "Accent2")
    local dur = 9 + math.random() * 9
    TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, math.random() * 5), { Position = UDim2.fromScale(math.clamp(x + (math.random() - 0.5) * 0.15, 0, 1), -0.05) }):Play()
end

local MainStroke = Stroke(Main, Color3.new(1, 1, 1), 1.5, 0)
local MainGrad = New("UIGradient", { Rotation = 0 }, MainStroke)
OnTheme(function() MainGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Stroke), ColorSequenceKeypoint.new(0.35, Theme.Accent), ColorSequenceKeypoint.new(0.65, Theme.Accent2), ColorSequenceKeypoint.new(1, Theme.Stroke) }) end)
TweenService:Create(MainGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 }):Play()
local MainScale = New("UIScale", { Scale = TargetScale() }, Main)

local Shadow = New("Frame", { Size = UDim2.fromOffset(BW, BH), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 0, Visible = false }, Screen)
local ShadowScale = New("UIScale", { Scale = 1 }, Shadow)
local ShadowLayers = {}
for i, g in ipairs({ 8, 20, 36, 56 }) do
    local l = New("Frame", { Size = UDim2.new(1, g * 2, 1, g * 2), Position = UDim2.fromOffset(-g, -g + 10), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0) }, Shadow)
    Corner(l, 18 + g); ShadowLayers[i] = { f = l, base = 0.82 + i * 0.03 }
end
local ShadowGlow = New("Frame", { Size = UDim2.new(1, 40, 1, 40), Position = UDim2.fromOffset(-20, -20), BorderSizePixel = 0 }, Shadow)
Corner(ShadowGlow, 38); Bind(ShadowGlow, "BackgroundColor3", "Accent"); ShadowLayers[#ShadowLayers + 1] = { f = ShadowGlow, base = 0.95 }
Track(RunService.RenderStepped:Connect(function()
    local vis = Main.Visible; Shadow.Visible = vis
    if not vis then return end
    Shadow.Position = Main.Position; Shadow.Size = Main.Size; ShadowScale.Scale = MainScale.Scale
    local a = Main.GroupTransparency
    for _, l in ipairs(ShadowLayers) do l.f.BackgroundTransparency = 1 - (1 - l.base) * (1 - a) end
end))

local TopGlow = New("Frame", { Size = UDim2.new(0.8, 0, 0, 1), Position = UDim2.fromScale(0.1, 0), BorderSizePixel = 0 }, Main)
Bind(TopGlow, "BackgroundColor3", "Accent")
New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }) }, TopGlow)

local Opening = false
local function ApplyScale(animate)
    if Opening then return end
    if animate and Main.Visible then Tween(MainScale, 0.25, { Scale = TargetScale() }, Enum.EasingStyle.Quint) else MainScale.Scale = TargetScale() end
end
Track(Screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() ApplyScale(false) end))

local function PlayToggleSound(on, big)
    if not Config.SoundEnabled then return end
    pcall(function()
        local function play(id, vol, speed)
            local s = Instance.new("Sound")
            s.SoundId = id; s.Volume = vol; s.PlaybackSpeed = speed; s.Parent = SoundService; s:Play()
            Debris:AddItem(s, 2.5); return s
        end
        local speed = (on and 1.18 or 0.86) * (big and 0.85 or 1)
        local s = play(on and SOUND_ON or SOUND_OFF, big and 0.7 or 0.6, speed)
        task.delay(0.35, function() if s.Parent and s.TimeLength == 0 then play(SOUND_FALLBACK, 0.55, on and 1.35 or 0.85) end end)
    end)
end

local function PlayOpen()
    Main.Visible = true
    Main.GroupTransparency = 0
    Tween(MainScale, 0.3, { Scale = TargetScale() }, Enum.EasingStyle.Back)
    PlayToggleSound(true, true)
end
local function PlayClose()
    Main.Visible = false
    PlayToggleSound(false, true)
end
local function SetWindow(visible)
    SetConfig("WindowVisible", visible)
    if visible then PlayOpen() else PlayClose() end
end

local function SavePosition(target, kx, ky)
    local s = Screen.AbsoluteSize
    if s.X <= 0 or s.Y <= 0 then return end
    local c = target.AbsolutePosition + target.AbsoluteSize / 2
    local fx = math.clamp(c.X / s.X, 0.02, 0.98)
    local fy = math.clamp(c.Y / s.Y, 0.02, 0.98)
    target.Position = UDim2.fromScale(fx, fy)
    SetConfig(kx, math.floor(fx * 10000) / 10000); SetConfig(ky, math.floor(fy * 10000) / 10000)
end

local function MakeDraggable(handle, target, kx, ky, onClick)
    local dragging, dragInput, startPos, startCenter, moved = false, nil, nil, nil, false
    handle.InputBegan:Connect(function(input)
        if IsPointer(input) then dragging = true; moved = false; dragInput = input; startPos = input.Position; startCenter = target.AbsolutePosition + target.AbsoluteSize / 2 end
    end)
    Track(UIS.InputChanged:Connect(function(input)
        if not dragging or not IsMove(input) then return end
        if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end
        local d = input.Position - startPos
        if d.Magnitude > 8 then moved = true end
        if moved then
            local s = Screen.AbsoluteSize
            target.Position = UDim2.fromOffset(math.clamp(startCenter.X + d.X, 0, s.X), math.clamp(startCenter.Y + d.Y, 0, s.Y))
        end
    end))
    Track(UIS.InputEnded:Connect(function(input)
        if dragging and IsPointer(input) then
            if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end
            dragging = false
            if moved then SavePosition(target, kx, ky) elseif onClick then onClick() end
        end
    end))
end

local ActiveToast
local function Toast(text, on)
    if ActiveToast then ActiveToast:Destroy(); ActiveToast = nil end
    local t = New("TextLabel", { Size = UDim2.fromOffset(0, 38), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 48), BorderSizePixel = 0, Text = text, TextSize = 12, Font = FNT.M, BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.Text, ZIndex = 300 }, Screen)
    Corner(t, 19); Stroke(t, Theme.Accent, 1, 0.55); Pad(t, 38, 18, 0, 0)
    local dot = New("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, -24, 0.5, -4), BorderSizePixel = 0, BackgroundColor3 = (on == true) and RGB(70, 200, 120) or (on == false and Theme.Muted or Theme.Accent) }, t)
    Corner(dot, 4); ActiveToast = t
    Tween(t, 0.35, { Position = UDim2.new(0.5, 0, 1, -26) }, Enum.EasingStyle.Back)
    task.delay(1.7, function()
        if ActiveToast == t then
            Tween(t, 0.25, { Position = UDim2.new(0.5, 0, 1, 48) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.3, function() t:Destroy(); if ActiveToast == t then ActiveToast = nil end end)
        end
    end)
end

-- FPS/MS WIDGET
local StatsGui = New("ScreenGui", { Name = "RELWX_Stats", ResetOnSpawn = false, DisplayOrder = 999999, IgnoreGuiInset = true, Enabled = Config.StatsVisible }, PlayerGui)
local StatsBox = New("Frame", { Size = UDim2.fromOffset(152, 30), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(Config.StatsX, Config.StatsY), BorderSizePixel = 0, BackgroundTransparency = 0.1, Active = true }, StatsGui)
Bind(StatsBox, "BackgroundColor3", "Surface"); Corner(StatsBox, 15); Bind(Stroke(StatsBox, Theme.Stroke, 1, 0.2), "Color", "Stroke")
local FpsLabel = Text(StatsBox, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Center); FpsLabel.RichText = true; FpsLabel.Size = UDim2.new(0.5, -1, 1, 0)
local MsLabel = Text(StatsBox, "", 11, FNT.M, "Sub", Enum.TextXAlignment.Center); MsLabel.RichText = true; MsLabel.Position = UDim2.new(0.5, 1, 0, 0); MsLabel.Size = UDim2.new(0.5, -1, 1, 0)
local StatsDivider = New("Frame", { Size = UDim2.fromOffset(1, 14), Position = UDim2.new(0.5, 0, 0.5, -7), BorderSizePixel = 0 }, StatsBox)
Bind(StatsDivider, "BackgroundColor3", "Stroke")
MakeDraggable(StatsBox, StatsBox, "StatsX", "StatsY")

local Metrics = { fps = 60, ping = 0 }
do
    local frames, acc = 0, 0
    Track(RunService.RenderStepped:Connect(function(dt)
        frames = frames + 1; acc = acc + dt
        if acc >= 0.5 then Metrics.fps = math.floor(frames / acc + 0.5); frames, acc = 0, 0 end
    end))
end
local function GetPing()
    local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
    if ok and type(ping) == "number" and ping > 0 then return math.floor(ping * 1000 + 0.5) end
    return 0
end
local function Level(value, good, mid, higherIsBetter)
    local g, m, b = RGB(70, 200, 120), RGB(240, 190, 60), RGB(235, 75, 90)
    if higherIsBetter then return value >= good and g or (value >= mid and m or b) end
    return value <= good and g or (value <= mid and m or b)
end
local function RefreshStats()
    Metrics.ping = GetPing()
    local fc = Level(Metrics.fps, 50, 30, true)
    local mc = Level(Metrics.ping, 80, 160, false)
    local muted = "#" .. Theme.Muted:ToHex()
    FpsLabel.Text = string.format('<font color="#%s"><b>%d</b></font> <font color="%s">FPS</font>', fc:ToHex(), Metrics.fps, muted)
    if Metrics.ping <= 0 then MsLabel.Text = string.format('<font color="#%s"><b>N/A</b></font> <font color="%s">MS</font>', Theme.Muted:ToHex(), muted)
    else MsLabel.Text = string.format('<font color="#%s"><b>%d</b></font> <font color="%s">MS</font>', mc:ToHex(), Metrics.ping, muted) end
end

-- TOP BAR
local Top = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, BorderSizePixel = 0 }, Main)
local TopLine = New("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, -1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, Top)
do local g = AccentGrad(TopLine, 0); g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 0.95) }) end

local Badge = New("Frame", { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(16, 13), BorderSizePixel = 0 }, Top)
Badge.BackgroundColor3 = Color3.new(1, 1, 1); AccentGrad(Badge, 45); Corner(Badge, 10); Bind(Stroke(Badge, Theme.Accent, 1.5, 0.65), "Color", "Accent")
local BadgeText = Text(Badge, "RX", 13, FNT.B, nil, Enum.TextXAlignment.Center); BadgeText.Size = UDim2.fromScale(1, 1); Bind(BadgeText, "TextColor3", "OnAccent")

local Brand = Text(Top, "", 15, FNT.B, "Text"); Brand.RichText = true
OnTheme(function() Brand.Text = 'RELWX <font color="#' .. Theme.Accent:ToHex() .. '">HUB</font>' end)
Brand.Position = UDim2.fromOffset(60, 10); Brand.Size = UDim2.new(1, -270, 0, 22)
local BrandSub = Text(Top, "NEXUS EDITION", 10, FNT.R, "Muted"); BrandSub.Position = UDim2.fromOffset(60, 31); BrandSub.Size = UDim2.new(1, -270, 0, 16)

local MaxBtn = New("TextButton", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -86, 0.5, -16), BackgroundColor3 = Theme.Surface2, Text = "□", TextSize = 20, Font = FNT.B, TextColor3 = Theme.Sub }, Top)
Corner(MaxBtn, 10)
local CloseBtn = New("TextButton", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -48, 0.5, -16), BackgroundColor3 = Theme.Surface2, Text = "×", TextSize = 20, Font = FNT.B, TextColor3 = Theme.Sub }, Top)
Corner(CloseBtn, 10)

CloseBtn.MouseButton1Click:Connect(function() SetWindow(false) end)
MakeDraggable(Top, Main, "WindowX", "WindowY")
MaxBtn.MouseButton1Click:Connect(function()
    SetConfig("Maximized", not Config.Maximized); SetConfig("WindowX", 0.5); SetConfig("WindowY", 0.5)
    Tween(Main, 0.3, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quint); ApplyScale(true)
end)

-- SIDEBAR
local Rail = New("Frame", { Size = UDim2.new(0, SW, 1, -80), Position = UDim2.fromOffset(12, 68), BorderSizePixel = 0 }, Main)
Bind(Rail, "BackgroundColor3", "Surface"); Corner(Rail, 14); Bind(Stroke(Rail, Theme.Stroke, 1, 0.4), "Color", "Stroke")
local CatList = New("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never }, Rail)
Bind(CatList, "ScrollBarImageColor3", "Accent"); List(CatList, 4); Pad(CatList, 0, 4, 1, 1)

local UserBox = New("Frame", { Size = UDim2.new(1, -16, 0, 52), Position = UDim2.new(0, 8, 1, -60), BorderSizePixel = 0 }, Rail)
Bind(UserBox, "BackgroundColor3", "Surface2"); Corner(UserBox, 12)
local Avatar = New("ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0, 9, 0.5, -17), BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60" }, UserBox)
Corner(Avatar, 17); Bind(Avatar, "BackgroundColor3", "Button"); Bind(Stroke(Avatar, Theme.Accent, 1.5, 0.2), "Color", "Accent"); Bind(Stroke(UserBox, Theme.Stroke, 1, 0.5), "Color", "Stroke")
local UName = Text(UserBox, LocalPlayer.DisplayName, 12, FNT.B, "Text"); UName.Position = UDim2.fromOffset(52, 9); UName.Size = UDim2.new(1, -58, 0, 18)
local UTag = Text(UserBox, "@" .. LocalPlayer.Name, 10, FNT.R, "Muted"); UTag.Position = UDim2.fromOffset(52, 27); UTag.Size = UDim2.new(1, -58, 0, 14)

local Pages = {}
local TabList = {}
local function CatGroup(name)
    local l = Text(CatList, name, 10, FNT.B, "Muted"); l.Size = UDim2.new(1, 0, 0, 26); l.LayoutOrder = Next(CatList); Pad(l, 10, 0, 6, 0); return l
end
local CurrentTab = nil
local function SelectTab(id)
    if not Pages[id] then id = "Home" end
    SetConfig("LastTab", id)
    local changed = id ~= CurrentTab
    CurrentTab = id
    for pid, page in pairs(Pages) do page.Visible = (pid == id) end
    if changed then
        local p = Pages[id]; p.Position = UDim2.fromOffset(0, 16)
        Tween(p, 0.32, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
    end
    for _, t in ipairs(TabList) do 
        t.btn.BackgroundColor3 = (t.id == id) and Theme.Accent or Theme.Button
        t.btn.BackgroundTransparency = (t.id == id) and 0.84 or 1
        t.lbl.TextColor3 = (t.id == id) and Theme.Text or Theme.Sub
    end
end
local function Category(name, id)
    local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = Next(CatList) }, CatList)
    Corner(b, 11)
    local lbl = Text(b, name, 13, FNT.M)
    lbl.Position = UDim2.fromOffset(16, 0); lbl.Size = UDim2.new(1, -20, 1, 0); lbl.TextColor3 = Theme.Sub
    table.insert(TabList, { id = id, btn = b, lbl = lbl })
    b.MouseButton1Click:Connect(function() SelectTab(id) end)
end

-- PAGES
local Body = New("Frame", { Size = UDim2.new(1, -(SW + 36), 1, -80), Position = UDim2.fromOffset(SW + 24, 68), BackgroundTransparency = 1 }, Main)
local function MakePage(id, title, subtitle)
    local page = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false }, Body)
    Bind(page, "ScrollBarImageColor3", "Stroke"); List(page, 8); Pad(page, 0, 8, 0, 14)
    local t = Text(page, title, 22, FNT.B, "Text"); t.Size = UDim2.new(1, 0, 0, 28)
    local s = Text(page, subtitle or "", 11, FNT.R, "Muted"); s.Position = UDim2.fromOffset(0, 29); s.Size = UDim2.new(1, 0, 0, 18)
    local hb = New("Frame", { Size = UDim2.fromOffset(36, 3), Position = UDim2.fromOffset(0, 53), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, page)
    Corner(hb, 2); AccentGrad(hb, 0)
    Pages[id] = page
    return page
end
local function Section(page, title)
    local hdr = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = Next(page) }, page)
    local bar = New("Frame", { Size = UDim2.fromOffset(3, 14), Position = UDim2.new(0, 2, 0.5, -7), BorderSizePixel = 0 }, hdr)
    Corner(bar, 2); bar.BackgroundColor3 = Color3.new(1, 1, 1); AccentGrad(bar, 90)
    local label = Text(hdr, title, 13, FNT.B, "Text"); label.Position = UDim2.fromOffset(14, 0); label.Size = UDim2.new(1, -44, 1, 0)
    return hdr
end

local function CreateFarmButton(page, cropName, displayName, icon)
    local btn = Panel(page, UDim2.new(1, 0, 0, 56), "TextButton")
    HoverRow(btn)
    local t = Text(btn, icon .. "  " .. displayName, 13, FNT.M, "Text"); t.Position = UDim2.fromOffset(18, 0); t.Size = UDim2.new(1, -36, 1, 0)
    btn.MouseButton1Click:Connect(function()
        if cropName == "Sandwish" or cropName == "MangoRice" or cropName == "KangSom" then
            Toast("🍳 เริ่มคราฟ " .. cropName, true)
            task.spawn(function() CraftFoodAtStation(cropName, function() return true end) end)
        elseif cropName == "ProcessBanana" then
            Toast("🍌 เริ่มแปรรูปกล้วย", true)
            task.spawn(function() ProcessBananaAtStation(function() return true end) end)
        elseif cropName == "ProcessRock" then
            Toast("🔥 เริ่มหลอมหิน", true)
            task.spawn(function() ProcessOreAtStation("Rock", 2, function() return true end) end)
        elseif cropName == "ProcessSvibranium" then
            Toast("⚡ เริ่มหลอมไวเบรเนียม", true)
            task.spawn(function() ProcessOreAtStation("Svibranium", 4, function() return true end) end)
        elseif cropName == "DepositVault" then
            Toast("🏦 เก็บของเข้าตู้เซฟ", true)
            task.spawn(function() DepositAllToVault(function() return true end) end)
        elseif cropName == "SellMarket" then
            Toast("💰 ขายของที่ตลาด", true)
            task.spawn(function() SellAtEconomyMarket(function() return true end) end)
        elseif cropName == "AutoFishing" then
            if not isAutoFishingEnabled then StartAutoFishing(); Toast("🎣 เริ่มตกปลา", true)
            else StopAutoFishing(); Toast("🛑 หยุดตกปลา", false) end
        elseif cropName == "WarpTown" then
            Toast("🚀 วาปไปเบิกรถที่เมือง", true)
            task.spawn(function() WarpToTownAndSpawnCar() end)
        else
            Toast("🚜 เริ่มฟาร์ม " .. cropName .. "...", true)
            task.spawn(function() HarvestSingleCrop(cropName, 60, function() return true end) end)
        end
    end)
    return btn
end

-- HOME PAGE
local Home = MakePage("Home", "หน้าหลัก", "RELWX HUB x NEXUS TYPER TOWN")
local Welcome = Panel(Home, UDim2.new(1, 0, 0, 84)); Tint(Welcome)
local WelcomeText = Text(Welcome, "RELWX HUB", 22, FNT.B, "Text"); WelcomeText.Position = UDim2.fromOffset(20, 12); WelcomeText.Size = UDim2.new(1, -40, 0, 30)
local WelcomeSub = Text(Welcome, "ยินดีต้อนรับ, " .. LocalPlayer.DisplayName, 11, FNT.M, "Muted"); WelcomeSub.Position = UDim2.fromOffset(20, 46); WelcomeSub.Size = UDim2.new(1, -40, 0, 20)

local InfoCard = Panel(Home, UDim2.new(1, 0, 0, 120))
local InfoTitle = Text(InfoCard, "📊 สถิติ", 14, FNT.B, "Text"); InfoTitle.Position = UDim2.fromOffset(16, 12); InfoTitle.Size = UDim2.new(1, -32, 0, 20)
local InfoGrid = New("Frame", { Size = UDim2.new(1, -32, 0, 0), Position = UDim2.fromOffset(16, 40), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, InfoCard)
New("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 32), CellPadding = UDim2.fromOffset(10, 5), SortOrder = Enum.SortOrder.LayoutOrder }, InfoGrid)
local StatFpsHome = Text(InfoGrid, "FPS: --", 11, FNT.M, "Text"); StatFpsHome.Size = UDim2.fromScale(1, 1)
local StatPingHome = Text(InfoGrid, "MS: --", 11, FNT.M, "Text"); StatPingHome.Size = UDim2.fromScale(1, 1)
local StatPlayerHome = Text(InfoGrid, "ผู้เล่น: --", 11, FNT.M, "Text"); StatPlayerHome.Size = UDim2.fromScale(1, 1)
local StatTimeHome = Text(InfoGrid, "เวลา: 00:00", 11, FNT.M, "Text"); StatTimeHome.Size = UDim2.fromScale(1, 1)

-- DEX PAGE
local DexPage = MakePage("Dex", "พิกัด DEX", "ระบบฟาร์ม NEXUS HUB ครบวงจร")

Section(DexPage, "🚗 ยานพาหนะ")
CreateFarmButton(DexPage, "WarpTown", "วาปไปเบิกรถที่เมือง", "🚀")
CreateFarmButton(DexPage, "DepositVault", "เก็บของเข้าตู้เซฟ", "🏦")
CreateFarmButton(DexPage, "SellMarket", "ขายของที่ตลาด", "💰")

Section(DexPage, "🌾 ฟาร์มพืช")
CreateFarmButton(DexPage, "Bread", "ขนมปัง (Bread)", "🍞")
CreateFarmButton(DexPage, "Catchup", "ซอสมะเขือเทศ (Catchup)", "🍅")
CreateFarmButton(DexPage, "Mango", "มะม่วง (Mango)", "🥭")
CreateFarmButton(DexPage, "Rice", "ข้าว (Rice)", "🌾")
CreateFarmButton(DexPage, "Tomato", "มะเขือเทศ (Tomato)", "🍅")
CreateFarmButton(DexPage, "Banana", "กล้วย (Banana)", "🍌")
CreateFarmButton(DexPage, "Coconut", "มะพร้าว (Coconut)", "🥥")
CreateFarmButton(DexPage, "Corn", "ข้าวโพด (Corn)", "🌽")
CreateFarmButton(DexPage, "Sugarcane", "อ้อย (Sugarcane)", "🎋")

Section(DexPage, "🐷 ฟาร์มสัตว์")
CreateFarmButton(DexPage, "Pig", "หมู (Pig)", "🐷")
CreateFarmButton(DexPage, "Crab", "ปู (Crab)", "🦀")
CreateFarmButton(DexPage, "Egg", "ไข่ไก่ (Egg)", "🥚")
CreateFarmButton(DexPage, "Milk", "นม (Milk)", "🥛")

Section(DexPage, "⛏️ ฟาร์มเหมือง")
CreateFarmButton(DexPage, "Rock", "หิน (Rock)", "🪨")
CreateFarmButton(DexPage, "Svibranium", "ไวเบรเนียม (Svibranium)", "💎")

Section(DexPage, "🍳 แปรรูป / หลอมแร่")
CreateFarmButton(DexPage, "ProcessRock", "หลอมหิน (Process Rock)", "🔥")
CreateFarmButton(DexPage, "ProcessSvibranium", "หลอมไวเบรเนียม", "⚡")
CreateFarmButton(DexPage, "ProcessBanana", "แปรรูปกล้วย", "🍌")

Section(DexPage, "🍱 คราฟอาหาร")
CreateFarmButton(DexPage, "Sandwish", "แซนวิช", "🥪")
CreateFarmButton(DexPage, "MangoRice", "ข้าวมันมะม่วง", "🥭")
CreateFarmButton(DexPage, "KangSom", "แกงส้ม", "🍲")

Section(DexPage, "🎣 ตกปลา")
CreateFarmButton(DexPage, "AutoFishing", "เปิด/ปิด ตกปลาอัตโนมัติ", "🎣")

-- SYSTEM PAGE
local SystemPage = MakePage("System", "ระบบ", "ข้อมูลการทำงาน")
local SysCard = Panel(SystemPage, UDim2.new(1, 0, 0, 64))
local SysTitle = Text(SysCard, "สถานะระบบ", 13, FNT.M, "Text"); SysTitle.Position = UDim2.fromOffset(16, 11); SysTitle.Size = UDim2.new(1, -32, 0, 20)
local SysDesc = Text(SysCard, "RELWX x NEXUS | Anti-Kick Active", 11, FNT.R, "Muted"); SysDesc.Position = UDim2.fromOffset(16, 33); SysDesc.Size = UDim2.new(1, -32, 0, 18)

-- SETTINGS PAGE
local Settings = MakePage("Settings", "ตั้งค่า", "ปรับแต่ง UI")
Section(Settings, "ระบบ")
local SoundRow = Panel(Settings, UDim2.new(1, 0, 0, 50), "TextButton")
HoverRow(SoundRow)
local SoundLabel = Text(SoundRow, "เสียงเปิด/ปิด UI", 12, FNT.M, "Text"); SoundLabel.Position = UDim2.fromOffset(16, 0); SoundLabel.Size = UDim2.new(1, -32, 1, 0)
SoundRow.MouseButton1Click:Connect(function()
    Config.SoundEnabled = not Config.SoundEnabled
    SetConfig("SoundEnabled", Config.SoundEnabled)
    Toast("เสียง: " .. (Config.SoundEnabled and "เปิด" or "ปิด"), Config.SoundEnabled)
end)

-- SIDEBAR CATEGORIES
CatGroup("เมนูหลัก")
Category("🏠 หน้าหลัก", "Home")
Category("🎯 พิกัด DEX", "Dex")
CatGroup("ระบบ")
Category("⚙️ ระบบ", "System")
Category("🔧 ตั้งค่า", "Settings")

-- FLOATING RX BUTTON
local ToggleGui = New("ScreenGui", { Name = "RELWX_Floating", ResetOnSpawn = false, DisplayOrder = 999999, IgnoreGuiInset = true }, PlayerGui)
local Float = New("Frame", { Size = UDim2.fromOffset(48, 48), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(Config.FloatX, Config.FloatY), BackgroundTransparency = 1, Active = true }, ToggleGui)
local Glow = New("Frame", { Size = UDim2.new(1, 8, 1, 8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }, Float)
Corner(Glow, 15)
local GlowStroke = Stroke(Glow, RGB(145, 145, 145), 3, 0.2)
local RX = New("TextButton", { Size = UDim2.fromScale(1, 1), Text = "RX", TextSize = 15, Font = FNT.B, BorderSizePixel = 0, AutoButtonColor = false, Active = true }, Float)
Corner(RX, 13)
local RXStroke = Stroke(RX, RGB(255, 255, 255), 2, 0.05)
local RXGrad = New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 0) }) }, RXStroke)
TweenService:Create(RXGrad, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 }):Play()
OnTheme(function()
    local bg = Hex("FloatingButtonColor", RGB(18, 18, 18))
    RX.BackgroundColor3 = bg; RX.TextColor3 = Lum(bg) > 0.55 and RGB(15, 15, 15) or RGB(255, 255, 255)
    RXStroke.Color = Hex("FloatingBorderColor", RGB(255, 255, 255)); GlowStroke.Color = Hex("FloatingGlowColor", RGB(145, 145, 145))
end)
TweenService:Create(GlowStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.65 }):Play()
MakeDraggable(RX, Float, "FloatX", "FloatY", function() SetWindow(not Config.WindowVisible) end)

-- START
SelectTab(Config.LastTab)
RefreshStats()

task.spawn(function()
    while Screen.Parent do
        RefreshStats()
        if StatFpsHome then
            StatFpsHome.Text = "FPS: " .. tostring(Metrics.fps)
            StatFpsHome.TextColor3 = Level(Metrics.fps, 50, 30, true)
            StatPingHome.Text = "MS: " .. tostring(Metrics.ping)
            StatPingHome.TextColor3 = Level(Metrics.ping, 80, 160, false)
            StatPlayerHome.Text = "ผู้เล่น: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
            local sec = math.max(0, os.time() - sessionStart)
            StatTimeHome.Text = string.format("เวลา: %02d:%02d", math.floor(sec / 60), sec % 60)
        end
        task.wait(0.5)
    end
end)

if Config.WindowVisible then 
    Main.Visible = true
    Main.GroupTransparency = 0
    MainScale.Scale = TargetScale()
end
if not LoadedFromFile then SaveConfig(true) end

print("[RELWX x NEXUS] FULL VERSION Loaded Successfully!")
