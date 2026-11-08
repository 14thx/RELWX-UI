--// ============================================================
--//  RELWX HUB x NEXUS TYPER TOWN  |  ULTIMATE EDITION
--//  - UI RELWX v7 + ระบบฟาร์ม NEXUS HUB V4.3
--//  - แยกแท็บชัดเจน: พืช / สัตว์ / เหมือง / แปรรูป / ตกปลา
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
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
-- 1. GAME VARIABLES
-- ==============================================================================
local TOWN_CAR_SPAWN = Vector3.new(-311.83, 17.5, 5490.39)
local VehicleDriveSpeed = 300
local isAutoEatAndDrinkEnabled = true
local isAutoFishingEnabled = false
local fishingThread = nil
local fishingPlatform = nil
local isAutoHopOnPlayerNearbyEnabled = true
local autoHopDistance = 60
local isHopping = false
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

-- ==============================================================================
-- 2. CORE GAME FUNCTIONS (จาก NEXUS HUB V4.3)
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
    if stats then
        local hv = stats:GetAttribute("Hunger")
        if typeof(hv) == "number" then return hv end
    end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local hv = pd:GetAttribute("Hunger") or pd:GetAttribute("Food")
        if typeof(hv) == "number" then return hv end
    end
    return 100
end

local function GetPlayerEnergy()
    local stats = LocalPlayer:FindFirstChild("Stats")
    if stats then
        local bv = stats:GetAttribute("Brain") or stats:GetAttribute("Energy") or stats:GetAttribute("Thirst")
        if typeof(bv) == "number" then return bv end
    end
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    if pd then
        local bv = pd:GetAttribute("Brain") or pd:GetAttribute("Energy") or pd:GetAttribute("Thirst")
        if typeof(bv) == "number" then return bv end
    end
    return 100
end

local function FindAvailableFood()
    local pd = LocalPlayer:FindFirstChild("PlayerData")
    local itemFolder = LocalPlayer:FindFirstChild("Item")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    local foodCandidates = { "Sushi", "RiceKapaoMoo", "MangoRice", "Rice", "Sandwish", "Burger", "Bread", "Watermelon", "Curry", "Ramen", "Onigiri" }
    for _, food in ipairs(foodCandidates) do
        if pd then
            local count = pd:GetAttribute(food)
            if typeof(count) == "number" and count > 0 then return food end
        end
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
        if pd then
            local count = pd:GetAttribute(drink)
            if typeof(count) == "number" and count > 0 then return drink end
        end
        if itemFolder and itemFolder:FindFirstChild(drink) and itemFolder[drink].Value > 0 then return drink end
        if bp and bp:FindFirstChild(drink) then return drink end
        if char and char:FindFirstChild(drink) then return drink end
    end
    return nil
end

local function UseItem(itemName)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_inventory", "Use", itemName)
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
            if remCore then
                local Remotes_m = require(remCore)
                Remotes_m.Fire("_inventory", "Use", itemName)
            else
                UseItem(itemName)
            end
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
                if tool.Parent ~= char then
                    hum:EquipTool(tool)
                    task.wait(0.25)
                end
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
        else
            task.wait(1.5)
        end
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
        if food and (hunger == nil or hunger < targetPercent) then
            ConsumeItemSafely(food, true, 5.5)
            task.wait(0.4)
            hunger = GetPlayerHunger()
        end
        if drink and (brain == nil or brain < targetPercent) then
            ConsumeItemSafely(drink, false, 5.5)
            task.wait(0.4)
            brain = GetPlayerEnergy()
        end
        if (not food or (hunger and hunger >= targetPercent)) and (not drink or (brain and brain >= targetPercent)) then break end
        loopCount = loopCount + 1
        task.wait(0.3)
    end
end

local function CheckAndAutoEat()
    if not isAutoEatAndDrinkEnabled or isConsumingItem then return end
    local hunger = GetPlayerHunger()
    local brain = GetPlayerEnergy()
    if (hunger and hunger <= 80) or (brain and brain <= 80) then
        AutoEatThenDrink(95)
    end
end

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
            if v:IsA("Model") and IsMyVehicle(v) and v.PrimaryPart then
                MY_SPAWNED_CAR = v
                return v
            end
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
    local nearestCar = nil
    local minDist = math.huge
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
    if hum.Sit and hum.SeatPart == seat then
        MY_SPAWNED_CAR = car
        return true
    end
    if hum.Sit and hum.SeatPart ~= seat then hum.Sit = false; task.wait(0.2) end
    GrantAntiXGrace(20)
    local drivePrompt = nil
    local pFolder = seat:FindFirstChild("Prompt")
    if pFolder and pFolder:FindFirstChild("Prompt") and pFolder.Prompt:IsA("ProximityPrompt") then
        drivePrompt = pFolder.Prompt
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
    maxTimeout = maxTimeout or 50
    stopDist = stopDist or 2.5
    local startTime = os.clock()
    local lastPos = root.Position
    local stuckTicks = 0
    while (root.Position - targetPos).Magnitude > stopDist and (os.clock() - startTime < maxTimeout) do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(5)
        hum:MoveTo(targetPos)
        if (root.Position - lastPos).Magnitude < 0.4 then
            stuckTicks = stuckTicks + 1
            if stuckTicks >= 3 then hum.Jump = true; stuckTicks = 0 end
        else stuckTicks = 0 end
        lastPos = root.Position
        task.wait(0.15)
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
    EnsurePlayerSeatedInCar(myCar)
    task.wait(0.1)
    local currentPos = seat.Position
    local startY = currentPos.Y
    local initialGround = GetGroundLevel(currentPos.X, currentPos.Z, startY)
    local naturalRideHeight = math.clamp(startY - initialGround, 2.3, 3.2)
    local distTotal = (Vector2.new(destination.X, destination.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude
    if distTotal < 5 then return true end
    local traveled = 0
    local lastTick = os.clock()
    while traveled < distTotal do
        if shouldContinueCheck and not shouldContinueCheck() then return false end
        GrantAntiXGrace(15)
        if not hum.Sit or hum.SeatPart ~= seat then
            pcall(function() root.CFrame = seat.CFrame + Vector3.new(0, 0.8, 0); seat:Sit(hum) end)
        end
        local currentSpeed = tonumber(VehicleDriveSpeed) or 200
        currentSpeed = math.clamp(currentSpeed, 10, 500)
        local now = os.clock()
        local dt = math.min(now - lastTick, 0.1)
        lastTick = now
        traveled = math.min(distTotal, traveled + (currentSpeed * dt))
        local alpha = math.clamp(traveled / distTotal, 0, 1)
        local targetX = currentPos.X + (destination.X - currentPos.X) * alpha
        local targetZ = currentPos.Z + (destination.Z - currentPos.Z) * alpha
        local estY = currentPos.Y + (destination.Y - currentPos.Y) * alpha
        local groundY = GetGroundLevel(targetX, targetZ, estY)
        local naturalH = naturalRideHeight or 2.4
        local surfaceY = groundY + naturalH
        local dir = Vector3.new(destination.X - targetX, 0, destination.Z - targetZ)
        local lookCFrame = CFrame.new(targetX, surfaceY, targetZ)
        if dir.Magnitude > 0.1 then
            lookCFrame = CFrame.lookAt(Vector3.new(targetX, surfaceY, targetZ), Vector3.new(targetX, surfaceY, targetZ) + dir)
        end
        myCar:PivotTo(lookCFrame)
        RunService.Heartbeat:Wait()
    end
    local endGround = GetGroundLevel(destination.X, destination.Z, destination.Y)
    local targetEndY = (destination.Y < 5.0 and (destination.Y + naturalRideHeight)) or math.max(endGround + naturalRideHeight, 6.0)
    myCar:PivotTo(CFrame.new(destination.X, targetEndY, destination.Z))
    task.wait(0.1)
    return true
end

local function GetNearestCarBooth(fromPos)
    fromPos = fromPos or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or TOWN_CAR_SPAWN
    local closestPos = nil
    local closestDist = math.huge
    for cropName, data in pairs(TYPER_LOCATIONS) do
        if data and data.Booth then
            local d = (data.Booth - fromPos).Magnitude
            if d < closestDist then closestDist = d; closestPos = data.Booth end
        end
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
                        if not matchKeyword or string.find(string.lower(prompt.ActionText or ""), string.lower(matchKeyword)) then
                            closest = prompt; closestDist = d
                        end
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
        if getconnections then
            for _, con in ipairs(getconnections(btn.MouseButton1Click)) do
                pcall(function() if con.Function then con.Function() end end)
            end
        end
        if firesignal then pcall(function() firesignal(btn.MouseButton1Click) end) end
    end)
end

local function SafeClickGuiButton(btn)
    if not btn or not btn:IsA("GuiButton") then return end
    pcall(function()
        if firesignal then pcall(function() firesignal(btn.MouseButton1Click) end) end
    end)
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

local function GetSpawnPointForBooth(boothPos)
    local bestPt = nil
    local bestDist = math.huge
    local farmSys = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Farm")
    if farmSys then
        for _, farm in ipairs(farmSys:GetChildren()) do
            local sp = farm:FindFirstChild("Prompt") and farm.Prompt:FindFirstChild("Spawn")
            local ptFolder = sp and sp:FindFirstChild("Point")
            if ptFolder then
                for _, pt in ipairs(ptFolder:GetChildren()) do
                    if pt:IsA("BasePart") then
                        local d = (pt.Position - boothPos).Magnitude
                        if d < bestDist then bestDist = d; bestPt = pt end
                    end
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
        if spPt and spPt:IsA("BasePart") then
            myCar:PivotTo(spPt.CFrame + Vector3.new(0, 1.2, 0))
        else
            local groundY = GetGroundLevel(boothPos.X, boothPos.Z, boothPos.Y)
            myCar:PivotTo(CFrame.new(boothPos.X, groundY + 1.2, boothPos.Z))
        end
        myCar.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
        myCar.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(2.0)
    ExitCarNaturally(myCar)
    if root and (root.Position - boothPos).Magnitude > 8 then
        SmoothWalkTo(boothPos, 3, nil, 5.0)
    end
    local boothPrompt = FindBoothPromptNear(boothPos, 40)
    if boothPrompt then
        boothPrompt.Enabled = true
        TriggerPrompt(boothPrompt)
    end
    local cs = PlayerGui:WaitForChild("Car_Spawn", 1.5)
    local t0 = os.clock()
    while (not cs or not cs:FindFirstChild("Group") or not cs.Group.Visible) and (os.clock() - t0 < 1.2) do
        if boothPrompt then TriggerPrompt(boothPrompt) end
        task.wait(0.15)
    end
    if cs and cs:FindFirstChild("Group") and cs.Group.Visible then
        local btn = cs.Group:FindFirstChild("Pound", true)
        if btn and btn:IsA("GuiButton") then ClickGuiButton(btn) end
    end
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Fire("_carspawn", "Despawn", carName)
            MY_SPAWNED_CAR = nil
        end
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
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.2)
        else
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(boothPos.X, root.Position.Y, boothPos.Z))
        end
    end
    local boothPrompt = FindBoothPromptNear(root.Position, 30) or (boothPos and FindBoothPromptNear(boothPos, 30))
    if boothPrompt then
        boothPrompt.Enabled = true
        TriggerPrompt(boothPrompt)
    end
    local cs = PlayerGui:FindFirstChild("Car_Spawn")
    local group = cs and cs:FindFirstChild("Group")
    local tOpen = os.clock()
    while os.clock() - tOpen < 3.0 do
        if group and group.Visible then break end
        if boothPrompt then TriggerPrompt(boothPrompt) end
        task.wait(0.1)
        cs = PlayerGui:FindFirstChild("Car_Spawn")
        group = cs and cs:FindFirstChild("Group")
    end
    if group and group.Visible then
        local spawnBtn = group:FindFirstChild("Spawn", true) or group:FindFirstChild("Buggy", true)
        if spawnBtn and spawnBtn:IsA("GuiButton") then ClickGuiButton(spawnBtn) end
        task.wait(1.0)
        local finalCar = GetNearbyPlayerVehicle(80) or GetPlayerVehicle()
        if finalCar then
            MY_SPAWNED_CAR = finalCar
            EnsurePlayerSeatedInCar(finalCar)
            if cs and cs:FindFirstChild("Group") then cs.Group.Visible = false end
            return finalCar
        end
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
    local townPos = Vector3.new(TOWN_CAR_SPAWN.X, groundY + 1.2, TOWN_CAR_SPAWN.Z)
    root.CFrame = CFrame.new(townPos)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.4)
    local car = SpawnCarAtBooth(TOWN_CAR_SPAWN)
    if car then EnsurePlayerSeatedInCar(car) end
    return car
end

local function EnsureCarAvailable(boothPos)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetBooth = boothPos or (root and GetNearestCarBooth(root.Position)) or TOWN_CAR_SPAWN
    local nearbyCar = GetNearbyPlayerVehicle(80)
    if nearbyCar and nearbyCar.PrimaryPart and IsMyVehicle(nearbyCar) then
        EnsurePlayerSeatedInCar(nearbyCar)
        return nearbyCar
    end
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
            if d <= 10 then
                local angle = math.atan2(hrp.Position.Z - centerPos.Z, hrp.Position.X - centerPos.X)
                table.insert(occupiedAngles, angle)
            end
        end
    end
    local bestAngle = nil
    local maxMinDist = -1
    for i = 0, 15 do
        local testAngle = (i / 16) * math.pi * 2
        local minDiff = math.pi
        for _, occAngle in ipairs(occupiedAngles) do
            local diff = math.abs(testAngle - occAngle)
            if diff > math.pi then diff = (math.pi * 2) - diff end
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
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                targetPrompt = desc
                break
            end
        end
    end
    if targetPrompt then
        local holdTime = math.max((targetPrompt.HoldDuration or 0.1), 0.15) + 0.12
        pcall(function() targetPrompt:InputHoldBegin() end)
        task.wait(holdTime)
        pcall(function() targetPrompt:InputHoldEnd() end)
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
        if myCar then EnsurePlayerSeatedInCar(myCar)
        else myCar = EnsureCarAvailable(locData and locData.Booth) end
    end
    local farmPos = locData.Farm
    local exactCenter = GetExactFarmPromptPosition(cropName) or farmPos
    local farmParkingPos = Vector3.new(exactCenter.X + 4.5, GetGroundLevel(exactCenter.X + 4.5, exactCenter.Z + 4.5, exactCenter.Y), exactCenter.Z + 4.5)
    DriveCarTo(farmParkingPos, shouldContinueCheck)
    task.wait(2.0)
    ExitCarNaturally(myCar)
    task.wait(0.3)
    local standPos, bestAngle = GetHumanLikeFarmStandingSpot(exactCenter)
    SmoothWalkTo(standPos, 6, shouldContinueCheck, 1.2)
    task.wait(0.2)
    if root then
        local finalGround = GetGroundLevel(standPos.X, standPos.Z, exactCenter.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(standPos.X, finalGround + 2.2, standPos.Z), Vector3.new(exactCenter.X, finalGround + 2.2, exactCenter.Z))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(1.5)
    local isFarming = false
    TriggerFarmPromptDirectly(cropName)
    task.wait(1.5)
    local afGui = PlayerGui:FindFirstChild("Auto Farm") or PlayerGui:FindFirstChild("AutoFarm")
    if afGui and ((afGui:FindFirstChild("Group") and afGui.Group.Visible) or afGui.Enabled) then isFarming = true end
    if not isFarming and GetPlayerInventoryCount(cropName) == curCount then
        task.wait(0.5)
        TriggerFarmPromptDirectly(cropName)
        task.wait(1.5)
    end
    local farmTimeout = os.clock()
    while curCount < targetAmount do
        if isAutoEatAndDrinkEnabled and not isConsumingItem then
            local h = GetPlayerHunger()
            local e = GetPlayerEnergy()
            if (h and h <= 75) or (e and e <= 75) then
                task.wait(0.3)
                if h and h <= 75 then CheckAndAutoEat() end
                task.wait(0.3)
                TriggerFarmPromptDirectly(cropName)
                task.wait(1.2)
                farmTimeout = os.clock()
            end
        end
        if shouldContinueCheck and not shouldContinueCheck() then break end
        if os.clock() - farmTimeout > 180 then break end
        GrantAntiXGrace(15)
        local newCount = GetPlayerInventoryCount(cropName)
        if newCount > curCount then
            curCount = newCount
            farmTimeout = os.clock()
        elseif (os.clock() - farmTimeout > 15) and (newCount == curCount) then
            TriggerFarmPromptDirectly(cropName)
            farmTimeout = os.clock()
        end
        task.wait(0.5)
    end
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
    DriveCarTo(marketPos, shouldContinueCheck)
    task.wait(0.3)
    ExitCarNaturally(myCar)
    if root then
        local gY = GetGroundLevel(marketPos.X, marketPos.Z, marketPos.Y)
        root.CFrame = CFrame.lookAt(Vector3.new(marketPos.X + 2.5, gY + 2.2, marketPos.Z), marketPos)
        root.AssemblyLinearVelocity = Vector3.zero
    end
    task.wait(0.2)
    local econPrompt = FindPromptNear(root.Position, 25, "econ")
    if econPrompt then TriggerPrompt(econPrompt) end
    task.wait(0.4)
    pcall(function()
        local remCore = ReplicatedStorage:FindFirstChild("Systems") and ReplicatedStorage.Systems:FindFirstChild("Modules") and ReplicatedStorage.Systems.Modules:FindFirstChild("Core") and ReplicatedStorage.Systems.Modules.Core:FindFirstChild("Remotes")
        if remCore then
            local Remotes_m = require(remCore)
            Remotes_m.Invoke("_economy", "SellAll")
            Remotes_m.Fire("_economy", "SellAll")
        end
    end)
    task.wait(1.0)
    pcall(function()
        local eg = PlayerGui:FindFirstChild("Economy")
        if eg and eg:FindFirstChild("Group") then eg.Group.Visible = false end
    end)
end

-- ==============================================================================
-- 3. RELWX UI FRAMEWORK (Simplified for brevity)
-- ==============================================================================
local Screen = Instance.new("ScreenGui")
Screen.Name = "RELWX_UI"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.Parent = PlayerGui

local Main = Instance.new("CanvasGroup")
Main.Size = UDim2.fromOffset(740, 580)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
Main.Parent = Screen

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 172, 1, -80)
Sidebar.Position = UDim2.fromOffset(12, 68)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Sidebar.Parent = Main

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -208, 1, -80)
Body.Position = UDim2.fromOffset(196, 68)
Body.BackgroundTransparency = 1
Body.Parent = Main

local Pages = {}
local Tabs = {}

local function CreatePage(id, title, subtitle)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = Body
    
    local t = Instance.new("TextLabel")
    t.Text = title
    t.Size = UDim2.new(1, 0, 0, 30)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextSize = 22
    t.TextColor3 = Color3.new(1,1,1)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = page
    
    Pages[id] = page
    return page
end

local function SelectTab(id)
    for pid, page in pairs(Pages) do page.Visible = (pid == id) end
    for _, btn in pairs(Tabs) do
        btn.BackgroundColor3 = (btn.Name == id) and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(30, 30, 35)
    end
end

local function CreateTabButton(id, text)
    local btn = Instance.new("TextButton")
    btn.Name = id
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = Sidebar
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = Sidebar
    
    btn.MouseButton1Click:Connect(function() SelectTab(id) end)
    Tabs[id] = btn
end

-- ==============================================================================
-- 4. สร้างแท็บแยกตามหมวดหมู่
-- ==============================================================================
-- 4.1 หน้าหลัก
local HomePage = CreatePage("Home", "หน้าหลัก", "ยินดีต้อนรับ")
local Welcome = Instance.new("Frame")
Welcome.Size = UDim2.new(1, 0, 0, 84)
Welcome.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Welcome.Parent = HomePage
local WText = Instance.new("TextLabel")
WText.Text = "RELWX x NEXUS HUB"
WText.Size = UDim2.fromScale(1, 1)
WText.BackgroundTransparency = 1
WText.Font = Enum.Font.GothamBold
WText.TextSize = 20
WText.TextColor3 = Color3.new(1,1,1)
WText.Parent = Welcome

-- 4.2 แท็บฟาร์มพืช
local CropPage = CreatePage("Crop", "ฟาร์มพืช", "เลือกพืชที่ต้องการฟาร์ม")
local function AddCropCard(parent, name, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = "  " .. text
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.GothamMedium
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = parent
    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            HarvestSingleCrop(name, 60, function() return true end)
        end)
    end)
end
AddCropCard(CropPage, "Bread", "🍞 ขนมปัง (Bread)")
AddCropCard(CropPage, "Catchup", "🍅 ซอสมะเขือเทศ (Catchup)")
AddCropCard(CropPage, "Mango", "🥭 มะม่วง (Mango)")
AddCropCard(CropPage, "Rice", "🌾 ข้าว (Rice)")
AddCropCard(CropPage, "Tomato", "🍅 มะเขือเทศ (Tomato)")
AddCropCard(CropPage, "Banana", "🍌 กล้วย (Banana)")

-- 4.3 แท็บฟาร์มสัตว์
local AnimalPage = CreatePage("Animal", "ฟาร์มสัตว์", "เลือกสัตว์ที่ต้องการฟาร์ม")
AddCropCard(AnimalPage, "Pig", "🐷 หมู (Pig)")
AddCropCard(AnimalPage, "Crab", "🦀 ปู (Crab)")

-- 4.4 แท็บฟาร์มเหมือง
local MinePage = CreatePage("Mine", "ฟาร์มเหมือง", "เลือกแร่ที่ต้องการขุด")
AddCropCard(MinePage, "Rock", "🪨 หิน (Rock)")
AddCropCard(MinePage, "Svibranium", "💎 ไวเบรเนียม (Svibranium)")

-- 4.5 แท็บแปรรูป
local ProcessPage = CreatePage("Process", "แปรรูป/คราฟ", "คราฟอาหารและแปรรูปวัตถุดิบ")
local ProcessBtn = Instance.new("TextButton")
ProcessBtn.Size = UDim2.new(1, 0, 0, 50)
ProcessBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ProcessBtn.Text = "  🍳 คราฟแซนวิช (Sandwich)"
ProcessBtn.TextXAlignment = Enum.TextXAlignment.Left
ProcessBtn.Font = Enum.Font.GothamMedium
ProcessBtn.TextColor3 = Color3.new(1,1,1)
ProcessBtn.Parent = ProcessPage
ProcessBtn.MouseButton1Click:Connect(function()
    task.spawn(function() CraftFoodAtStation("Sandwish", function() return true end) end)
end)

-- 4.6 แท็บตกปลา
local FishPage = CreatePage("Fish", "ตกปลา", "ระบบตกปลาอัตโนมัติ")
local FishToggle = Instance.new("TextButton")
FishToggle.Size = UDim2.new(1, 0, 0, 50)
FishToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
FishToggle.Text = "  เริ่ม/หยุด ตกปลาอัตโนมัติ"
FishToggle.TextXAlignment = Enum.TextXAlignment.Left
FishToggle.Font = Enum.Font.GothamMedium
FishToggle.TextColor3 = Color3.new(1,1,1)
FishToggle.Parent = FishPage
local isFishOn = false
FishToggle.MouseButton1Click:Connect(function()
    isFishOn = not isFishOn
    if isFishOn then
        StartAutoFishing()
        FishToggle.Text = "  🟢 กำลังตกปลา... (กดเพื่อหยุด)"
    else
        StopAutoFishing()
        FishToggle.Text = "  เริ่ม/หยุด ตกปลาอัตโนมัติ"
    end
end)

-- 4.7 แท็บตั้งค่า
local SysPage = CreatePage("System", "ตั้งค่า", "ตั้งค่าต่างๆ")
local HopBtn = Instance.new("TextButton")
HopBtn.Size = UDim2.new(1, 0, 0, 50)
HopBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 80)
HopBtn.Text = "  🌐 ย้ายเซิร์ฟเวอร์หนีคน (Server Hop)"
HopBtn.TextXAlignment = Enum.TextXAlignment.Left
HopBtn.Font = Enum.Font.GothamMedium
HopBtn.TextColor3 = Color3.new(1,1,1)
HopBtn.Parent = SysPage
HopBtn.MouseButton1Click:Connect(function()
    HopServer("กดปุ่มย้ายเซิร์ฟเวอร์")
end)

-- ==============================================================================
-- 5. สร้างปุ่มเมนูด้านซ้าย
-- ==============================================================================
CreateTabButton("Home", "🏠 หน้าหลัก")
CreateTabButton("Crop", "🌾 ฟาร์มพืช")
CreateTabButton("Animal", "🐷 ฟาร์มสัตว์")
CreateTabButton("Mine", "⛏️ ฟาร์มเหมือง")
CreateTabButton("Process", "🍳 แปรรูป")
CreateTabButton("Fish", "🎣 ตกปลา")
CreateTabButton("System", "⚙️ ตั้งค่า")

-- เริ่มต้นที่หน้าหลัก
SelectTab("Home")

-- ==============================================================================
-- 6. ปุ่มลอยเปิด/ปิด UI
-- ==============================================================================
local FloatGui = Instance.new("ScreenGui")
FloatGui.Name = "RELWX_Float"
FloatGui.ResetOnSpawn = false
FloatGui.Parent = PlayerGui

local RX = Instance.new("TextButton")
RX.Size = UDim2.fromOffset(48, 48)
RX.Position = UDim2.fromScale(0.05, 0.25)
RX.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
RX.Text = "RX"
RX.Font = Enum.Font.GothamBold
RX.TextSize = 16
RX.TextColor3 = Color3.fromRGB(0, 220, 255)
RX.Parent = FloatGui

local RXCorner = Instance.new("UICorner")
RXCorner.CornerRadius = UDim.new(0, 14)
RXCorner.Parent = RX

local RXStroke = Instance.new("UIStroke")
RXStroke.Color = Color3.fromRGB(0, 220, 255)
RXStroke.Thickness = 2
RXStroke.Parent = RX

local dragging = false
local startPos
RX.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        startPos = input.Position
    end
end)
RX.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startPos
        RX.Position = UDim2.new(RX.Position.X.Scale, RX.Position.X.Offset + delta.X, RX.Position.Y.Scale, RX.Position.Y.Offset + delta.Y)
        startPos = input.Position
    end
end)
RX.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

RX.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

print("[RELWX x NEXUS] UI Loaded Successfully!")
