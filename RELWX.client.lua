--// ============================================================
--//  RELWX HUB x NEXUS TYPER TOWN  |  PART 1/3
--// ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UIS = UserInputService

-- ANTI-KICK
pcall(function()
    local lp = Players.LocalPlayer
    if hookmetamethod then
        local oldNm
        oldNm = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if (method == "Kick" or method == "kick") and (self == lp or self == Players) then
                warn("🛡️ [RELWX ANTI-KICK] บล็อก Kick: " .. tostring(args[1] or "Unknown"))
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

-- GAME VARIABLES
local TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
local VehicleDriveSpeed = 300
local isAutoEatAndDrinkEnabled = true
local isAutoFishingEnabled = false
local MY_SPAWNED_CAR = nil
local isConsumingItem = false
local sessionStart = os.time()

local TYPER_LOCATIONS = {
    Bread = { Booth = Vector3.new(872.19, 15.90, 4682.54), Farm = Vector3.new(828.31, 11.21, 4817.85) },
    Catchup = { Booth = Vector3.new(1763.23, 14.23, 4206.70), Farm = Vector3.new(1803.05, 12.65, 4236.79) },
    Pig = { Booth = Vector3.new(306.01, 30.77, -1558.06), Farm = Vector3.new(268.61, 28.74, -1513.65) },
    Mango = { Booth = Vector3.new(-1855.59, 20.06, 586.40), Farm = Vector3.new(-1862.26, 17.33, 535.43) },
    Rice = { Booth = Vector3.new(-92.11, 11.46, 89.48), Farm = Vector3.new(-128.87, 11.02, 78.51) },
    Tomato = { Booth = Vector3.new(-2294.10, 31.28, -1273.91), Farm = Vector3.new(-2319.61, 27.21, -1229.19) },
    Banana = { Booth = Vector3.new(-1528.59, 30.34, -1253.46), Farm = Vector3.new(-1545.12, 28.80, -1126.87) },
    Crab = { Booth = Vector3.new(1442.30, 30.56, 613.34), Farm = Vector3.new(1400.27, 28.69, 648.22) },
    Rock = { Booth = Vector3.new(-4163.51, 25.33, -1234.29), Farm = Vector3.new(-4138.03, 29.88, -1286.63), Process = Vector3.new(-935.29, 6.93, 6786.66) },
    Svibranium = { Booth = Vector3.new(2785.16, 30.11, -262.38), Farm = Vector3.new(2723.67, 28.51, -236.17), Process = Vector3.new(-927.35, 6.93, 6763.02) },
    Food = { Crafting = Vector3.new(3442.48, 56.40, 3925.24), BananaProcess = Vector3.new(3429.20, 56.80, 3911.80) },
    Economy = { Market = Vector3.new(-462.0, 18.0, 5324.7) }
}

local FISHING_PARKING_POS = Vector3.new(-902.46, 3.41, 2964.32)
local FISHING_SPOT = Vector3.new(-955.06, -2.65, 2907.18)
local BAIT_SHOP_POS = Vector3.new(-949.31, 16.57, 4861.12)

-- CONFIG
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

-- THEME
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
    Theme.Bg = bg
    Theme.Surface = bg:Lerp(to, 0.05)
    Theme.Surface2 = bg:Lerp(to, 0.095)
    Theme.Stroke = bg:Lerp(to, 0.17)
    Theme.Text = dark and RGB(244, 244, 244) or RGB(20, 20, 20)
    Theme.Sub = Theme.Text:Lerp(bg, 0.32)
    Theme.Muted = Theme.Text:Lerp(bg, 0.58)
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
local function ApplyTheme()
    ComputeTheme()
    for _, fn in ipairs(ThemeHooks) do pcall(fn) end
end

-- HELPERS
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
local function List(parent, padding)
    return New("UIListLayout", { Padding = UDim.new(0, padding or 0), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
end
local function Text(parent, text, size, font, color, align)
    local l = New("TextLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Text = text or "", TextSize = size or 13, Font = font or Enum.Font.Gotham, TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd }, parent)
    if type(color) == "string" then Bind(l, "TextColor3", color) elseif color then l.TextColor3 = color end
    return l
end
local function Tween(obj, t, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function Apply(obj, animate, props)
    if animate then Tween(obj, 0.16, props) else for k, v in pairs(props) do obj[k] = v end end
end
local function Panel(parent, size, class)
    local f = New(class or "Frame", { BorderSizePixel = 0, LayoutOrder = Next(parent) }, parent)
    if class == "TextButton" then f.Text = ""; f.AutoButtonColor = false end
    if size then f.Size = size end
    Bind(f, "BackgroundColor3", "Surface")
    Corner(f, 12)
    Bind(Stroke(f, Theme.Stroke, 1, 0.4), "Color", "Stroke")
    return f
end
local function HoverRow(btn)
    local st = btn:FindFirstChildOfClass("UIStroke")
    btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface2 }); if st then Tween(st, 0.12, { Transparency = 0.05 }) end end)
    local sc
    if btn:IsA("GuiButton") then
        sc = New("UIScale", { Scale = 1 }, btn)
        btn.MouseButton1Down:Connect(function() Tween(sc, 0.08, { Scale = 0.982 }) end)
        btn.MouseButton1Up:Connect(function() Tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back) end)
    end
    btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = Theme.Surface }); if st then Tween(st, 0.12, { Transparency = 0.4 }) end; if sc then Tween(sc, 0.12, { Scale = 1 }) end end)
end
local function AccentGrad(parent, rotation)
    local g = New("UIGradient", { Rotation = rotation or 0 }, parent)
    OnTheme(function() g.Color = ColorSequence.new(Theme.Accent, Theme.Accent2) end)
    return g
end
local function IsPointer(input) return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch end
local function IsMove(input) return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch end

-- GAME FUNCTIONS
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
    return nil
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
            if remCore then local Remotes_m = require(remCore); Remotes_m.Fire("_inventory", "Use", itemName) end
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

local function GetCraft3Prompt()
    local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
    local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
    if c3 then
        local p = c3:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p and p.Enabled then return p end
        if c3:FindFirstChild("Prompt") then
            local pp = c3.Prompt:FindFirstChildWhichIsA("ProximityPrompt") or (c3.Prompt:IsA("ProximityPrompt") and c3.Prompt)
            if pp and pp.Enabled then return pp end
        end
    end
    if craftSys then
        for _, desc in ipairs(craftSys:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local p = desc.Parent
                while p and p ~= workspace do
                    if p.Name == "Craft_3" then return desc end
                    p = p.Parent
                end
            end
        end
    end
    return nil
end

local function CraftFoodAtStation(recipeName, shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    -- ตรวจสอบและขึ้นรถเสมอเพื่อขับไปโต๊ะคราฟท์
    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then
        myCar = EnsureCarAvailable()
    end
    if myCar then
        EnsurePlayerSeatedInCar(myCar)
    end

    -- 1. ปิด UI ที่อาจค้างอยู่
    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then procGui.Group.Visible = false end
        local ecoGui = PlayerGui:FindFirstChild("Economy")
        if ecoGui and ecoGui:FindFirstChild("Group") then ecoGui.Group.Visible = false end
    end)

    -- 2. หาตำแหน่งที่แน่นอนของโต๊ะคราฟอาหาร Craft_3
    local cPrompt = GetCraft3Prompt()
    local exactCraftPos = nil
    if cPrompt then
        local pParent = cPrompt.Parent
        exactCraftPos = (pParent:IsA("BasePart") and pParent.Position)
                     or (pParent:IsA("Attachment") and pParent.WorldPosition)
                     or (pParent.Parent and pParent.Parent:IsA("BasePart") and pParent.Parent.Position)
    end
    if not exactCraftPos then
        local craftSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Crafting")
        local c3 = craftSys and craftSys:FindFirstChild("Craft_3")
        if c3 then
            local anyPart = c3:FindFirstChildWhichIsA("BasePart", true)
            if anyPart then exactCraftPos = anyPart.Position end
        end
    end
    exactCraftPos = exactCraftPos or foodData.Crafting

    -- 3. ขับรถไปจอดหน้าโต๊ะคราฟอาหาร Craft_3
    DriveCarTo(exactCraftPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.2)
    if shouldContinueCheck and not shouldContinueCheck() then return end

    -- 4. ลงจากรถและยืนหน้าโต๊ะคราฟ
    if hum.Sit then
        hum.Sit = false
        task.wait(0.2)
    end

    local groundY = GetGroundLevel(exactCraftPos.X, exactCraftPos.Z, exactCraftPos.Y)
    local standPos = Vector3.new(exactCraftPos.X, groundY + 3.0, exactCraftPos.Z + 2.5)
    root.CFrame = CFrame.lookAt(standPos, exactCraftPos)
    task.wait(0.15)

    -- 5. กด ProximityPrompt เฉพาะของโต๊ะ Craft_3 เท่านั้น
    cPrompt = cPrompt or GetCraft3Prompt()
    if cPrompt then
        TriggerPrompt(cPrompt)
    end

    -- 6. รอ UI Crafting เปิดขึ้นมา
    local cg = PlayerGui:WaitForChild("Crafting", 4)
    local tWaitUI = os.clock()
    while os.clock() - tWaitUI < 3.0 do
        if cg and cg:FindFirstChild("Group") and cg.Group.Visible then break end
        if cPrompt then TriggerPrompt(cPrompt) end
        task.wait(0.3)
    end

    if not cg or not cg:FindFirstChild("Group") or not cg.Group.Visible then
        pcall(function()
            if cg and cg:FindFirstChild("Group") then
                cg.Group.Visible = true
                cg.Group.GroupTransparency = 0
            end
        end)
    end
    task.wait(0.2)

    -- 7. คำนวณจำนวนที่คราฟได้จริง
    local function GetMaxCraftAmount()
        local b = GetPlayerInventoryCount("Bread")
        local c = GetPlayerInventoryCount("Catchup")
        local p = GetPlayerInventoryCount("Pig")
        local m = GetPlayerInventoryCount("Mango")
        local r = GetPlayerInventoryCount("Rice")
        if recipeName == "Sandwish" then
            return math.min(math.floor(b / 3), math.floor(c / 2), math.floor(p / 2))
        elseif recipeName == "MangoRice" then
            return math.min(math.floor(m / 2), math.floor(r / 3))
        elseif recipeName == "RiceKapaoMoo" then
            return math.min(math.floor(p / 2), math.floor(r / 3))
        elseif recipeName == "KangSom" then
            local tom = GetPlayerInventoryCount("Tomato")
            local cr = GetPlayerInventoryCount("Crab")
            return math.min(math.floor(tom / 2), math.floor(cr / 2))
        end
        return 1
    end

    local toCraft = GetMaxCraftAmount()
    if toCraft <= 0 then
        pcall(function()
            if cg and cg:FindFirstChild("Group") then cg.Group.Visible = false end
        end)
        local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
        if myCar2 then EnsurePlayerSeatedInCar(myCar2) end
        return
    end

    -- 8. เลือกหมวดหมู่ Sand (อาหาร) และเลือกเมนูใน UI Crafting
    local mainFrame = cg and cg:FindFirstChild("Group") and cg.Group:FindFirstChild("Main")
    if mainFrame then
        local scroller = mainFrame:FindFirstChild("Left_Tab") and mainFrame.Left_Tab:FindFirstChild("ScrollingFrame")
        if scroller then
            local sandCatBtn = scroller:FindFirstChild("Sand") or scroller:FindFirstChild("Food") or scroller:FindFirstChild("อาหาร")
            if sandCatBtn then
                SafeClickGuiButton(sandCatBtn)
                task.wait(0.2)
            end

            local recipeBtn = scroller:FindFirstChild(recipeName) or mainFrame:FindFirstChild(recipeName, true)
            if recipeBtn then
                local clickTarget = (recipeBtn:IsA("GuiButton") and recipeBtn) or recipeBtn:FindFirstChildWhichIsA("GuiButton", true) or recipeBtn
                if clickTarget and clickTarget:IsA("GuiButton") then
                    SafeClickGuiButton(clickTarget)
                end
                task.wait(0.2)
            end
        end

        -- ใส่จำนวนลงใน Amount Box
        local amtBox = mainFrame:FindFirstChild("Function") and mainFrame.Function:FindFirstChild("Amount") and mainFrame.Function.Amount:FindFirstChild("Amount")
        if amtBox and amtBox:IsA("TextBox") then
            amtBox.Text = tostring(toCraft)
            task.wait(0.1)
        end

        -- กดปุ่ม Craft บน UI
        local craftBtn = mainFrame:FindFirstChild("Button") and mainFrame.Button:FindFirstChild("Craft")
        if craftBtn and craftBtn:IsA("GuiButton") then
            SafeClickGuiButton(craftBtn)
        end
    end

    -- 9. ยิง Remote Request เพื่อสั่งคราฟกับเซิร์ฟเวอร์โดยตรง
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_crafting", "Request", "Craft_3", recipeName, toCraft, false)
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_crafting") then
                rem._crafting:FireServer("Request", "Craft_3", recipeName, toCraft, false)
            end
        end
    end)

    -- รอระยะเวลาคราฟ 10.5 วินาที
    local tStart = os.clock()
    while (os.clock() - tStart < 10.0) do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        GrantAntiXGrace(15)
        task.wait(0.5)
    end
    task.wait(0.2)

    -- 10. ยิง Remote Complete เพื่อรับไอเทมอาหารสำเร็จ
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_crafting", "Complete", "Craft_3", recipeName, toCraft, false)
        else
            local rem = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Remotes")
            if rem and rem:FindFirstChild("_crafting") then
                rem._crafting:FireServer("Complete", "Craft_3", recipeName, toCraft, false)
            end
        end
    end)
    task.wait(0.3)

    -- 11. ปิดหน้าต่าง UI คราฟ
    pcall(function()
        if mainFrame and mainFrame:FindFirstChild("Exit") then
            if firesignal then firesignal(mainFrame.Exit.MouseButton1Click) end
        end
        if cg and cg:FindFirstChild("Group") then
            cg.Group.Visible = false
        end
    end)
    task.wait(0.2)

    -- รอ 3 วินาทีแล้วขึ้นรถไปขาย
    task.wait(3.0)

    local myCar3 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar3 then
        EnsurePlayerSeatedInCar(myCar3)
    end
    task.wait(0.3)
end

local function ProcessBananaAtStation(shouldContinueCheck)
    local foodData = TYPER_LOCATIONS.Food
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then
        myCar = EnsureCarAvailable()
    end
    if myCar then
        EnsurePlayerSeatedInCar(myCar)
    end

    local pBan = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild("Banana")
    local pPrompt = pBan and pBan:FindFirstChild("Prompt")
    local bPos = nil
    if pPrompt then
        bPos = (pPrompt:IsA("Attachment") and pPrompt.WorldPosition) or (pPrompt:IsA("BasePart") and pPrompt.Position) or (pPrompt:FindFirstChildWhichIsA("BasePart") and pPrompt:FindFirstChildWhichIsA("BasePart").Position)
    end
    if not bPos and pBan then
        local anyPart = pBan:FindFirstChildWhichIsA("BasePart", true)
        if anyPart then bPos = anyPart.Position end
    end
    local exactBanPos = bPos or foodData.BananaProcess

    DriveCarTo(exactBanPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.1)
    if shouldContinueCheck and not shouldContinueCheck() then return end

    if hum.Sit then
        hum.Sit = false
        task.wait(0.1)
    end

    local standPos = exactBanPos + Vector3.new(0, 0, 2.5)
    local groundY = GetGroundLevel(standPos.X, standPos.Z, standPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, groundY + 3.0, standPos.Z), exactBanPos)
    task.wait(0.1)

    local procPrompt = pBan and pBan:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not procPrompt then
        procPrompt = FindPromptNear(root.Position, 15, nil)
    end
    if procPrompt then
        TriggerPrompt(procPrompt)
    end
    task.wait(0.3)

    local tProc = os.clock()
    while (GetPlayerInventoryCount("Banana") >= 2) and (os.clock() - tProc < 120) do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        GrantAntiXGrace(15)
        task.wait(3.2)
    end

    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then
            local mainFrame = procGui.Group:FindFirstChild("Main")
            if mainFrame and mainFrame:FindFirstChild("Exit") and firesignal then
                firesignal(mainFrame.Exit.MouseButton1Click)
            end
            procGui.Group.Visible = false
        end
    end)
    task.wait(0.2)

    task.wait(3.0)

    local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(TOWN_CAR_SPAWN)
    if myCar2 then
        EnsurePlayerSeatedInCar(myCar2)
    end
    task.wait(0.3)
end

local function ProcessOreAtStation(oreName, requiredMin, shouldContinueCheck)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local locData = TYPER_LOCATIONS[oreName]
    local exactProcPos = (locData and locData.Process) or Vector3.new(-935.29, 6.93, 6786.66)

    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then
        myCar = EnsureCarAvailable()
    end
    if myCar then
        EnsurePlayerSeatedInCar(myCar)
    end

    DriveCarTo(exactProcPos + Vector3.new(0, 0, 5.0), shouldContinueCheck)
    task.wait(0.1)
    if shouldContinueCheck and not shouldContinueCheck() then return end

    if hum.Sit then
        hum.Sit = false
        task.wait(0.1)
    end

    local standPos = exactProcPos + Vector3.new(0, 0, 2.5)
    local groundY = GetGroundLevel(standPos.X, standPos.Z, standPos.Y)
    root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, groundY + 3.0, standPos.Z), exactProcPos)
    task.wait(0.1)

    local pFolder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Process") and workspace.Systems.Process:FindFirstChild(oreName)
    local procPrompt = pFolder and pFolder:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not procPrompt then
        procPrompt = FindPromptNear(root.Position, 20, nil)
    end
    if procPrompt then
        TriggerPrompt(procPrompt)
    end
    task.wait(0.3)

    -- กดเริ่ม Process ผ่าน Remote และ ActionBtn
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_process", "Start", oreName)
        end
    end)

    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then
            local mainFrame = procGui.Group:FindFirstChild("Main")
            local actionBtn = mainFrame and mainFrame:FindFirstChild("ActionBtn")
            if actionBtn and firesignal then
                firesignal(actionBtn.MouseButton1Click)
            end
        end
    end)

    requiredMin = requiredMin or (oreName == "Svibranium" and 4 or 2)
    local tProc = os.clock()
    while (GetPlayerInventoryCount(oreName) >= requiredMin) and (os.clock() - tProc < 180) do
        if shouldContinueCheck and not shouldContinueCheck() then break end
        GrantAntiXGrace(15)
        task.wait(3.2)
    end

    -- ปิดการแปรรูป
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_process", "Stop")
        end
    end)

    pcall(function()
        local procGui = PlayerGui:FindFirstChild("Process")
        if procGui and procGui:FindFirstChild("Group") then
            local mainFrame = procGui.Group:FindFirstChild("Main")
            if mainFrame and mainFrame:FindFirstChild("Exit") and firesignal then
                firesignal(mainFrame.Exit.MouseButton1Click)
            end
            procGui.Group.Visible = false
        end
    end)
    task.wait(0.2)

    task.wait(3.0)

    local myCar2 = GetNearbyPlayerVehicle(80) or EnsureCarAvailable(Vector3.new(-876.62, 10.52, 6662.98))
    if myCar2 then
        EnsurePlayerSeatedInCar(myCar2)
    end
    task.wait(0.3)
end

local VAULT_COORDS = Vector3.new(-1.98, 26.54, 8632.61)

local function DepositAllToVault(shouldContinueCheck)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    local myCar = GetPlayerVehicle()
    if not myCar or not hum.Sit then
        EnsureCarAvailable()
    end

    DriveCarTo(VAULT_COORDS + Vector3.new(0, 0, 8.0), shouldContinueCheck)
    task.wait(0.2)
    if shouldContinueCheck and not shouldContinueCheck() then return end

    local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
    if remCore then
        local Remotes_m = require(remCore)
        local pData = LocalPlayer:FindFirstChild("PlayerData")
        if pData then
            for attrName, _ in pairs(pData:GetAttributes()) do
                local count = GetPlayerInventoryCount(attrName)
                if count > 0 then
                    pcall(function()
                        Remotes_m.Invoke("_vault_tx", "Deposit", attrName, count)
                    end)
                    task.wait(0.15)
                end
            end
        end
    end

    task.wait(0.3)

    local carAfterVault = GetPlayerVehicle()
    if not carAfterVault then
        carAfterVault = EnsureCarAvailable(TOWN_CAR_SPAWN)
    end
    if carAfterVault then
        EnsurePlayerSeatedInCar(carAfterVault)
    end
    task.wait(0.2)
end
-- ROOT GUI
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

-- (ข้าม FX เพื่อความกระชับ ใช้ของเดิม)
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

-- FPS / MS WIDGET
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

local function WindowButton(kind, xOffset, danger)
    local b = New("TextButton", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, xOffset, 0.5, -16), BorderSizePixel = 0, Text = "", AutoButtonColor = false }, Top)
    Corner(b, 10); Bind(b, "BackgroundColor3", "Surface2")
    local paint = Icon(b, kind, 7, 7); OnTheme(function() paint(Theme.Sub) end)
    b.MouseEnter:Connect(function() Tween(b, 0.12, { BackgroundColor3 = danger and RGB(200, 70, 80) or Theme.Button }); paint(danger and RGB(255, 255, 255) or Theme.Text) end)
    b.MouseLeave:Connect(function() Tween(b, 0.12, { BackgroundColor3 = Theme.Surface2 }); paint(Theme.Sub) end)
    return b
end
local MaxBtn = WindowButton("max", -86, false)
local CloseBtn = WindowButton("close", -48, true)
CloseBtn.MouseButton1Click:Connect(function() SetWindow(false) end)
MakeDraggable(Top, Main, "WindowX", "WindowY")
MaxBtn.MouseButton1Click:Connect(function()
    SetConfig("Maximized", not Config.Maximized); SetConfig("WindowX", 0.5); SetConfig("WindowY", 0.5)
    Tween(Main, 0.3, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quint); ApplyScale(true)
end)

-- SIDEBAR
local Rail = New("Frame", { Size = UDim2.new(0, SW, 1, -80), Position = UDim2.fromOffset(12, 68), BorderSizePixel = 0 }, Main)
Bind(Rail, "BackgroundColor3", "Surface"); Corner(Rail, 14); Bind(Stroke(Rail, Theme.Stroke, 1, 0.4), "Color", "Stroke")
local CatList = New("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -80), Position = UDim2.fromOffset(8, 10), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never }, Rail)
Bind(CatList, "ScrollBarImageColor3", "Accent"); List(CatList, 4); Pad(CatList, 0, 4, 1, 1)

local UserBox = New("Frame", { Size = UDim2.new(1, -16, 0, 52), Position = UDim2.new(0, 8, 1, -60), BorderSizePixel = 0 }, Rail)
Bind(UserBox, "BackgroundColor3", "Surface2"); Corner(UserBox, 12)
local Avatar = New("ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0, 9, 0.5, -17), BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60" }, UserBox)
Corner(Avatar, 17); Bind(Avatar, "BackgroundColor3", "Button"); Bind(Stroke(Avatar, Theme.Accent, 1.5, 0.2), "Color", "Accent"); Bind(Stroke(UserBox, Theme.Stroke, 1, 0.5), "Color", "Stroke")
local Online = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 36, 0.5, 7), BorderSizePixel = 0, BackgroundColor3 = RGB(70, 200, 120), ZIndex = 3 }, UserBox)
Corner(Online, 5); Bind(Stroke(Online, Theme.Surface2, 2, 0), "Color", "Surface2")
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
    for _, t in ipairs(TabList) do t.active = (t.id == id); t.paint() end
end
local function Category(name, id, iconKind)
    local b = New("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = Next(CatList) }, CatList)
    Corner(b, 11)
    local bst = Stroke(b, Theme.Accent, 1, 1)
    local ind = New("Frame", { Size = UDim2.fromOffset(3, 8), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0 }, b)
    Corner(ind, 2)
    local setIcon = Icon(b, iconKind, 16, 12)
    local lbl = Text(b, name, 13, FNT.M); lbl.Position = UDim2.fromOffset(44, 0); lbl.Size = UDim2.new(1, -48, 1, 0); lbl.TextColor3 = Theme.Sub
    local tab = { id = id, active = false, hover = false }
    function tab.paint()
        Tween(b, 0.15, { BackgroundColor3 = tab.active and Theme.Accent or Theme.Button, BackgroundTransparency = tab.active and 0.84 or (tab.hover and 0.5 or 1) })
        Tween(bst, 0.15, { Color = Theme.Accent, Transparency = tab.active and 0.55 or 1 })
        Tween(lbl, 0.15, { TextColor3 = tab.active and Theme.Text or Theme.Sub })
        Tween(ind, 0.15, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = tab.active and 0 or 1, Size = tab.active and UDim2.fromOffset(3, 22) or UDim2.fromOffset(3, 8) })
        setIcon(tab.active and Theme.Accent or Theme.Sub)
    end
    TabList[#TabList + 1] = tab; OnTheme(tab.paint)
    b.MouseEnter:Connect(function() tab.hover = true; tab.paint() end)
    b.MouseLeave:Connect(function() tab.hover = false; tab.paint() end)
    b.MouseButton1Click:Connect(function() SelectTab(id) end)
    return b
end

-- PAGES & SECTIONS
local Body = New("Frame", { Size = UDim2.new(1, -(SW + 36), 1, -80), Position = UDim2.fromOffset(SW + 24, 68), BackgroundTransparency = 1 }, Main)
local function MakePage(id, title, subtitle)
    local page = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false }, Body)
    Bind(page, "ScrollBarImageColor3", "Stroke"); List(page, 8); Pad(page, 0, 8, 0, 14)
    local head = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, LayoutOrder = Next(page) }, page)
    local t = Text(head, title, 22, FNT.B, "Text"); t.Size = UDim2.new(1, 0, 0, 28)
    local s = Text(head, subtitle or "", 11, FNT.R, "Muted"); s.Position = UDim2.fromOffset(0, 29); s.Size = UDim2.new(1, 0, 0, 18)
    local hb = New("Frame", { Size = UDim2.fromOffset(36, 3), Position = UDim2.fromOffset(0, 53), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, head)
    Corner(hb, 2); AccentGrad(hb, 0)
    Pages[id] = page
    return page
end

local Collapsed = {}
for id in string.gmatch(Config.CollapsedSections, "[^|]+") do Collapsed[id] = true end
local function SaveCollapsed()
    local t = {}
    for id, v in pairs(Collapsed) do if v then t[#t + 1] = id end end
    table.sort(t); SetConfig("CollapsedSections", table.concat(t, "|"))
end
local SectionsByPage = {}
local CurrentSection = nil
local function Section(page, title)
    local hdr = New("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = Next(page) }, page)
    local bar = New("Frame", { Size = UDim2.fromOffset(3, 14), Position = UDim2.new(0, 2, 0.5, -7), BorderSizePixel = 0 }, hdr)
    Corner(bar, 2); bar.BackgroundColor3 = Color3.new(1, 1, 1); AccentGrad(bar, 90)
    local hl = New("Frame", { Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 1, -1), BorderSizePixel = 0 }, hdr)
    Bind(hl, "BackgroundColor3", "Stroke"); New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, hl)
    local label = Text(hdr, title, 13, FNT.B, "Text"); label.Position = UDim2.fromOffset(14, 0); label.Size = UDim2.new(1, -44, 1, 0)
    local chev = New("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -18, 0.5, 0), BackgroundTransparency = 1 }, hdr)
    local c1 = New("Frame", { Size = UDim2.fromOffset(8, 2), Position = UDim2.fromOffset(1, 6), Rotation = 45, BorderSizePixel = 0 }, chev)
    local c2 = New("Frame", { Size = UDim2.fromOffset(8, 2), Position = UDim2.fromOffset(6, 6), Rotation = -45, BorderSizePixel = 0 }, chev)
    Corner(c1, 1); Corner(c2, 1)
    OnTheme(function() c1.BackgroundColor3 = Theme.Muted; c2.BackgroundColor3 = Theme.Muted end)
    local sec = { label = hdr, items = {}, collapsed = Collapsed[title] == true }
    function sec.refresh(animate)
        for _, it in ipairs(sec.items) do it.frame.Visible = it.matched and not sec.collapsed end
        local rot = sec.collapsed and -90 or 0
        if animate then Tween(chev, 0.18, { Rotation = rot }) else chev.Rotation = rot end
    end
    sec.refresh(false)
    hdr.MouseButton1Click:Connect(function() sec.collapsed = not sec.collapsed; Collapsed[title] = sec.collapsed; SaveCollapsed(); sec.refresh(true) end)
    CurrentSection = sec; SectionsByPage[page] = SectionsByPage[page] or {}; table.insert(SectionsByPage[page], sec)
    return sec
end
local function Register(row, search)
    local sec = CurrentSection
    if sec then table.insert(sec.items, { frame = row, search = string.lower(search or ""), matched = true }); sec.refresh(false) end
end
local Refreshers = {}

-- COMPONENTS (ใช้ฟังก์ชัน Panel/Toggle/Slider จาก RELWX v7)
local UpdateSummary = function() end
local function Toggle(page, opts)
    local row = Panel(page, UDim2.new(1, 0, 0, 64), "TextButton"); HoverRow(row); Register(row, opts.title .. " " .. (opts.desc or ""))
    local rowStroke = row:FindFirstChildOfClass("UIStroke")
    local title = Text(row, opts.title, 13, FNT.M, "Text"); title.Position = UDim2.fromOffset(18, 11); title.Size = UDim2.new(1, -96, 0, 20)
    local desc = Text(row, opts.desc or "", 11, FNT.R, "Muted"); desc.Position = UDim2.fromOffset(18, 33); desc.Size = UDim2.new(1, -96, 0, 18)
    local strip = New("Frame", { Size = UDim2.fromOffset(3, 26), Position = UDim2.new(0, 4, 0.5, -13), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 }, row)
    Corner(strip, 2); AccentGrad(strip, 90)
    local glow = New("Frame", { Size = UDim2.fromOffset(62, 40), Position = UDim2.new(1, -71, 0.5, -20), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 }, row)
    Corner(glow, 20); AccentGrad(glow, 0)
    local track = New("Frame", { Size = UDim2.fromOffset(48, 26), Position = UDim2.new(1, -64, 0.5, -13), BorderSizePixel = 0 }, row)
    Corner(track, 13)
    local tStroke = Stroke(track, Theme.Stroke, 1, 0.2); Bind(tStroke, "Color", "Stroke")
    local fill = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 }, track)
    Corner(fill, 13); AccentGrad(fill, 0)
    local knob = New("Frame", { Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), BorderSizePixel = 0 }, track)
    Corner(knob, 10)
    local state = Config[opts.key] == true
    local function render(animate)
        Apply(track, animate, { BackgroundColor3 = Theme.Button })
        Apply(fill, animate, { BackgroundTransparency = state and 0 or 1 })
        Apply(glow, animate, { BackgroundTransparency = state and 0.82 or 1 })
        Apply(knob, animate, { Position = state and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = state and Theme.OnAccent or Theme.Sub })
        Apply(strip, animate, { BackgroundTransparency = state and 0 or 1 })
        Apply(tStroke, animate, { Color = state and Theme.Accent or Theme.Stroke })
        if rowStroke then Apply(rowStroke, animate, { Color = state and Theme.Accent or Theme.Stroke, Transparency = state and 0.55 or 0.4 }) end
        UpdateSummary()
    end
    OnTheme(function() render(false) end)
    local function set(v, fire)
        state = v; SetConfig(opts.key, v); render(true)
        if fire then PlayToggleSound(v); if opts.callback then task.spawn(opts.callback, v) end end
    end
    row.MouseButton1Click:Connect(function() set(not state, true) end)
    Refreshers[#Refreshers + 1] = function() state = Config[opts.key] == true; render(false); if opts.callback then task.spawn(opts.callback, state) end end
    if opts.callback then task.defer(opts.callback, state) end
    return { Get = function() return state end, Set = function(v) set(v, true) end }
end

-- สร้างปุ่มฟาร์มแบบง่าย
local function CreateFarmButton(page, cropName, displayName, icon)
    local btn = Panel(page, UDim2.new(1, 0, 0, 56), "TextButton")
    HoverRow(btn)
    local t = Text(btn, icon .. "  " .. displayName, 13, FNT.M, "Text")
    t.Position = UDim2.fromOffset(18, 0)
    t.Size = UDim2.new(1, -36, 1, 0)
    btn.MouseButton1Click:Connect(function()
        if cropName == "Sandwish" or cropName == "MangoRice" or cropName == "KangSom" then
            task.spawn(function() CraftFoodAtStation(cropName, function() return true end) end)
        elseif cropName == "ProcessBanana" then
            task.spawn(function() ProcessBananaAtStation(function() return true end) end)
        elseif cropName == "ProcessRock" then
            task.spawn(function() ProcessOreAtStation("Rock", 2, function() return true end) end)
        elseif cropName == "ProcessSvibranium" then
            task.spawn(function() ProcessOreAtStation("Svibranium", 4, function() return true end) end)
        elseif cropName == "DepositVault" then
            task.spawn(function() DepositAllToVault(function() return true end) end)
        elseif cropName == "SellMarket" then
            task.spawn(function() SellAtEconomyMarket(function() return true end) end)
        elseif cropName == "AutoFishing" then
            if not isAutoFishingEnabled then 
                isAutoFishingEnabled = true
                Toast("🎣 เริ่มตกปลา", true) 
            else 
                isAutoFishingEnabled = false
                Toast("🛑 หยุดตกปลา", false) 
            end
        elseif cropName == "WarpTown" then
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
local Welcome = Panel(Home, UDim2.new(1, 0, 0, 84))
Tint(Welcome)
local WelcomeText = Text(Welcome, "RELWX HUB", 22, FNT.B, "Text"); WelcomeText.Position = UDim2.fromOffset(20, 12); WelcomeText.Size = UDim2.new(1, -40, 0, 30)
local WelcomeSub = Text(Welcome, "ยินดีต้อนรับ, " .. LocalPlayer.DisplayName, 11, FNT.M, "Muted"); WelcomeSub.Position = UDim2.fromOffset(20, 46); WelcomeSub.Size = UDim2.new(1, -40, 0, 20)

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

Section(DexPage, "🐷 ฟาร์มสัตว์")
CreateFarmButton(DexPage, "Pig", "หมู (Pig)", "🐷")
CreateFarmButton(DexPage, "Crab", "ปู (Crab)", "🦀")

Section(DexPage, "⛏️ ฟาร์มเหมือง")
CreateFarmButton(DexPage, "Rock", "หิน (Rock)", "🪨")
CreateFarmButton(DexPage, "Svibranium", "ไวเบรเนียม (Svibranium)", "💎")

Section(DexPage, "🍳 แปรรูป / หลอมแร่")
CreateFarmButton(DexPage, "ProcessRock", "หลอมหิน (Process Rock)", "🔥")
CreateFarmButton(DexPage, "ProcessSvibranium", "หลอมไวเบรเนียม (Process Svibranium)", "⚡")
CreateFarmButton(DexPage, "ProcessBanana", "แปรรูปกล้วย (Banana Pack)", "🍌")

Section(DexPage, "🍱 คราฟอาหาร")
CreateFarmButton(DexPage, "Sandwish", "แซนวิช (Sandwich)", "🥪")
CreateFarmButton(DexPage, "MangoRice", "ข้าวมันมะม่วง (Mango Rice)", "🥭")
CreateFarmButton(DexPage, "KangSom", "แกงส้ม (Kang Som)", "🍲")

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
Category("หน้าหลัก", "Home", "grid")
Category("พิกัด DEX", "Dex", "sliders")
CatGroup("ระบบ")
Category("ระบบ", "System", "sliders")
Category("ตั้งค่า", "Settings", "ring")

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
        task.wait(0.5)
    end
end)

if Config.WindowVisible then 
    Main.Visible = true
    Main.GroupTransparency = 0
    MainScale.Scale = TargetScale()
end
if not LoadedFromFile then SaveConfig(true) end

print("[RELWX x NEXUS] FIXED EDITION Loaded Successfully!")
