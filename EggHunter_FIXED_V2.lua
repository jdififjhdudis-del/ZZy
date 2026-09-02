--// Humanoid Replacer
--// R6 / R15
--// Camera + Animations + Hidden Name

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local OldHumanoid = Character:FindFirstChildOfClass("Humanoid")

if not OldHumanoid then
warn("Humanoid not found")
return
end


---

-- Save original properties

local Data = {
WalkSpeed = OldHumanoid.WalkSpeed,
JumpPower = OldHumanoid.JumpPower,
JumpHeight = OldHumanoid.JumpHeight,
HipHeight = OldHumanoid.HipHeight,
AutoRotate = OldHumanoid.AutoRotate,

MaxHealth = OldHumanoid.MaxHealth,  
Health = OldHumanoid.Health,  

DisplayDistanceType = OldHumanoid.DisplayDistanceType,  
HealthDisplayType = OldHumanoid.HealthDisplayType,  

NameDisplayDistance = OldHumanoid.NameDisplayDistance,  
HealthDisplayDistance = OldHumanoid.HealthDisplayDistance,  

RigType = OldHumanoid.RigType,

}


---

-- Find Animate

local Animate = Character:FindFirstChild("Animate")

if Animate then
Animate.Disabled = true
end


---

-- Create new Humanoid

local NewHumanoid = Instance.new("Humanoid")

NewHumanoid.Name = "Humanoid"


---

-- Copy Attributes

for Name, Value in pairs(OldHumanoid:GetAttributes()) do
pcall(function()
NewHumanoid:SetAttribute(Name, Value)
end)
end


---

-- Restore properties

pcall(function()
NewHumanoid.WalkSpeed = Data.WalkSpeed
end)

pcall(function()
NewHumanoid.JumpPower = Data.JumpPower
end)

pcall(function()
NewHumanoid.JumpHeight = Data.JumpHeight
end)

pcall(function()
NewHumanoid.HipHeight = Data.HipHeight
end)

pcall(function()
NewHumanoid.AutoRotate = Data.AutoRotate
end)

pcall(function()
NewHumanoid.MaxHealth = Data.MaxHealth
end)

pcall(function()
NewHumanoid.Health = math.clamp(
Data.Health,
0,
Data.MaxHealth
)
end)

pcall(function()
NewHumanoid.RigType = Data.RigType
end)


---

-- Hide player name

NewHumanoid.DisplayDistanceType =
Enum.HumanoidDisplayDistanceType.None


---

-- Hide health bar

NewHumanoid.HealthDisplayType =
Enum.HumanoidHealthDisplayType.AlwaysOff

NewHumanoid.NameDisplayDistance = 0
NewHumanoid.HealthDisplayDistance = 0


---

-- Parent new Humanoid

NewHumanoid.Parent = Character

task.wait()


---

-- Create Animator

local NewAnimator = Instance.new("Animator")

NewAnimator.Name = "Animator"
NewAnimator.Parent = NewHumanoid


---

-- Remove old Humanoid

OldHumanoid:Destroy()

task.wait()


---

-- Restart Animate

if Animate and Animate.Parent == Character then
Animate.Disabled = false
end


---

-- Camera

local Camera = workspace.CurrentCamera

Camera.CameraType = Enum.CameraType.Custom
Camera.CameraSubject = NewHumanoid


---

-- Keep camera attached

local CameraConnection

CameraConnection = RunService.RenderStepped:Connect(function()

if not Character.Parent then  
    CameraConnection:Disconnect()  
    return  
end  

if not NewHumanoid.Parent then  
    CameraConnection:Disconnect()  
    return  
end  

if Camera.CameraSubject ~= NewHumanoid then  
    Camera.CameraSubject = NewHumanoid  
end  

if Camera.CameraType ~= Enum.CameraType.Custom then  
    Camera.CameraType = Enum.CameraType.Custom  
end

end)


---

-- Restart animations once more

task.wait(0.5)

if Animate and Animate.Parent == Character then

Animate.Disabled = true  

task.wait()  

Animate.Disabled = false

end


---

-- Final camera update

task.wait(0.2)

Camera.CameraSubject = NewHumanoid
Camera.CameraType = Enum.CameraType.Custom

print("================================")
print("Humanoid replaced successfully")
print("R6/R15:", tostring(Data.RigType))
print("Animations: ON")
print("Camera: ON")
print("Player Name: HIDDEN")
print("Health Bar: HIDDEN")
print("================================")

--// ============================================================
--// EGG HUNTER / BEST BEAST - FIXED V2
--// Map-aware version for the supplied Final_Complete_Map.json
--// ============================================================
--//
--// The supplied map exposes:
--//   RF/EggWorld/AskFieldEggSnapshot
--//   RF/EggWorld/AskFieldEggCarry
--// and field records contain:
--//   Uid, AreaId, NestId, AssetCategory, AssetScale, Mutations,
--//   BaseMutation, BottomCFrame, BoundsCFrame, BoundsSize, State.
--//
--// Ranking:
--//   1) highest calculated $/s
--//   2) highest weight (kg)
--//   3) highest rarity rank
--//
--// Performance:
--//   * one snapshot per refresh/click
--//   * no descendant scan on every frame
--//   * no RenderStepped loop for the hunter
--//   * one in-flight operation at a time
--//   * short timeouts around remote calls
--//
--// IMPORTANT:
--// A client script cannot force a server to award an egg. The supplied
--// game's server-side Carry request is the authoritative step.
--// ============================================================

task.spawn(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local HunterCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local CONFIG = {
        UI_NAME = "EggHunterUI",
        REMOTE_FOLDER = "EggWorld",
        SNAPSHOT_NAME = "AskFieldEggSnapshot",
        CARRY_NAME = "AskFieldEggCarry",

        -- The supplied map has SpawnLocation around this position.
        -- Dynamic SpawnLocation detection is preferred.
        FALLBACK_LOBBY = CFrame.new(513, 68, -363),

        TELEPORT_HEIGHT = 3,
        RETURN_HEIGHT = 4,

        REMOTE_TIMEOUT = 5,
        AFTER_TELEPORT_DELAY = 0.10,
        AFTER_CARRY_DELAY = 0.12,

        -- Only records that are actually available for pickup.
        VALID_STATES = {
            Slot = true,
        },

        -- Do not spam the server.
        ACTION_COOLDOWN = 1.0,
    }

    local state = {
        busy = false,
        lastAction = 0,
        cachedBest = nil,
        cachedRecords = {},
        generation = 0,
    }

    local function getCharacter()
        local c = LocalPlayer.Character
        if c and c.Parent then
            return c
        end
        return LocalPlayer.CharacterAdded:Wait()
    end

    local function getRoot()
        local c = getCharacter()
        local root = c:FindFirstChild("HumanoidRootPart")
            or c:FindFirstChild("RootPart")
            or c:FindFirstChild("UpperTorso")
            or c:FindFirstChild("Torso")
        return root
    end

    local function safeFind(parent, name)
        if not parent then
            return nil
        end

        local direct = parent:FindFirstChild(name)
        if direct then
            return direct
        end

        for _, obj in ipairs(parent:GetDescendants()) do
            if obj.Name == name then
                return obj
            end
        end

        return nil
    end

    local function findRemote(name)
        -- Prefer the exact hierarchy visible in the supplied map.
        local rf = ReplicatedStorage:FindFirstChild("RF")
        if rf then
            local eggWorld = rf:FindFirstChild(CONFIG.REMOTE_FOLDER)
            if eggWorld then
                local exact = eggWorld:FindFirstChild(name)
                if exact then
                    return exact
                end
            end
        end

        -- Fallback for executors that expose the remotes with a different
        -- replicated folder layout.
        return safeFind(ReplicatedStorage, name)
    end

    -- Remotes may not be replicated at the exact moment an executor starts.
    -- Keep the UI alive and resolve them asynchronously instead of returning.
    local SnapshotRemote = nil
    local CarryRemote = nil
    local remotesReady = false

    local function resolveRemotes(timeout)
        local deadline = os.clock() + (timeout or 12)

        while os.clock() < deadline do
            if not SnapshotRemote then
                SnapshotRemote = findRemote(CONFIG.SNAPSHOT_NAME)
            end
            if not CarryRemote then
                CarryRemote = findRemote(CONFIG.CARRY_NAME)
            end

            if SnapshotRemote and not SnapshotRemote:IsA("RemoteFunction") then
                SnapshotRemote = nil
            end
            if CarryRemote and not CarryRemote:IsA("RemoteFunction") then
                CarryRemote = nil
            end

            if SnapshotRemote and CarryRemote then
                remotesReady = true
                return true
            end

            task.wait(0.25)
        end

        remotesReady = false
        return false
    end

    local function invokeWithTimeout(remote, ...)
        local args = table.pack(...)
        local done = false
        local ok = false
        local result = nil
        local err = nil

        task.spawn(function()
            local success, a, b, c = pcall(function()
                return remote:InvokeServer(table.unpack(args, 1, args.n))
            end)

            ok = success
            if success then
                result = table.pack(a, b, c)
            else
                err = a
            end

            done = true
        end)

        local started = os.clock()
        while not done and os.clock() - started < CONFIG.REMOTE_TIMEOUT do
            task.wait()
        end

        if not done then
            return false, nil, "Remote timed out"
        end

        if not ok then
            return false, nil, tostring(err)
        end

        return true, result
    end

    local function getLobbyCFrame()
        -- First preference: the map's actual SpawnLocation.
        local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if spawn and spawn:IsA("BasePart") then
            return spawn.CFrame + Vector3.new(0, CONFIG.RETURN_HEIGHT, 0)
        end

        -- Common named lobby/spawn parts.
        local preferredNames = {
            "LobbySpawn",
            "Lobby",
            "Spawn",
            "SpawnLocation",
        }

        for _, name in ipairs(preferredNames) do
            local obj = safeFind(Workspace, name)
            if obj and obj:IsA("BasePart") then
                return obj.CFrame + Vector3.new(0, CONFIG.RETURN_HEIGHT, 0)
            elseif obj and obj:IsA("Model") then
                return obj:GetPivot() + Vector3.new(0, CONFIG.RETURN_HEIGHT, 0)
            end
        end

        return CONFIG.FALLBACK_LOBBY
    end

    local function teleportCharacter(cf)
        local character = getCharacter()
        if not character or not character.Parent then
            return false, "Character unavailable"
        end

        local root = getRoot()
        if not root then
            return false, "Root part unavailable"
        end

        -- PivotTo is used once per phase instead of a RenderStepped
        -- position loop, which avoids the frame-drop problem.
        local target = cf + Vector3.new(0, CONFIG.TELEPORT_HEIGHT, 0)

        local ok, err = pcall(function()
            character:PivotTo(target)
        end)

        if not ok then
            return false, tostring(err)
        end

        task.wait(CONFIG.AFTER_TELEPORT_DELAY)

        return true
    end

    local function tryGetModule(path)
        local current = ReplicatedStorage

        for _, part in ipairs(path) do
            current = current and current:FindFirstChild(part)
            if not current then
                return nil
            end
        end

        if not current or not current:IsA("ModuleScript") then
            return nil
        end

        local ok, result = pcall(require, current)
        if ok then
            return result
        end

        return nil
    end

    local Assets = tryGetModule({"Data", "Assets"})
    local AssetEarnings = tryGetModule({"Shared", "Util", "AssetEarnings"})
    local AssetItems = tryGetModule({"Shared", "Util", "AssetItems"})

    local function number(value, fallback)
        local n = tonumber(value)
        if n and n == n and n ~= math.huge and n ~= -math.huge then
            return n
        end
        return fallback or 0
    end

    local function getAssetDirectory(category)
        if not Assets or type(Assets) ~= "table" then
            return nil
        end

        local directory = Assets.Directory
        if type(directory) ~= "table" then
            return nil
        end

        return directory[category]
    end

    local function getRarityName(directory)
        if type(directory) ~= "table" then
            return "Unknown"
        end

        local rarity = directory.Rarity

        if type(rarity) == "table" then
            return tostring(
                rarity.DisplayName
                or rarity._id
                or rarity.Name
                or "Unknown"
            )
        end

        return tostring(rarity or "Unknown")
    end

    local function getRarityRank(directory)
        if type(directory) ~= "table" then
            return 0
        end

        local rarity = directory.Rarity

        if type(rarity) == "table" then
            return number(
                rarity.RarityNumber
                or rarity.Rank
                or rarity.Order,
                0
            )
        end

        return 0
    end

    local function buildAssetItem(record)
        return {
            Category = record.AssetCategory,
            Scale = number(record.AssetScale, 1),
            EyeColor = record.AssetEyeColor,
            ColorSeed = record.AssetColorSeed,
            ColorIndex = record.AssetColorIndex,
            Mutations = type(record.Mutations) == "table" and record.Mutations or {},
            BaseMutation = record.BaseMutation,
            Gender = record.AssetGender,
            Personality = record.AssetPersonality,
            IsStolenDNA = record.IsStolenDNA,
            HasBeenFirstPlaced = true,
        }
    end

    local function calculateWeight(record, directory)
        local scale = math.max(number(record.AssetScale, 1), 0)

        -- Exact formula found in the supplied map:
        -- ModelWeight * max(scale, 0)^3
        local modelWeight = type(directory) == "table"
            and number(directory.ModelWeight, 0)
            or 0

        if modelWeight > 0 then
            return modelWeight * (scale ^ 3)
        end

        -- If ModelWeight is unavailable, BoundsSize gives us a useful
        -- secondary size metric instead of breaking the ranking.
        local s = record.BoundsSize
        if typeof(s) == "Vector3" then
            return math.max(s.X, 0) * math.max(s.Y, 0) * math.max(s.Z, 0)
        end

        return scale
    end

    local function calculateRate(record)
        local item = buildAssetItem(record)

        -- Preferred: use the game's own earnings implementation.
        if AssetEarnings and type(AssetEarnings.LiveRatePerSecond) == "function" then
            local ok, rate = pcall(function()
                return AssetEarnings.LiveRatePerSecond(item)
            end)

            if ok and tonumber(rate) then
                return math.max(0, number(rate, 0))
            end
        end

        if AssetEarnings and type(AssetEarnings.RatePerSecond) == "function" then
            local ok, rate = pcall(function()
                return AssetEarnings.RatePerSecond(item)
            end)

            if ok and tonumber(rate) then
                return math.max(0, number(rate, 0))
            end
        end

        -- Fallback to the map's documented catalog earning formula.
        local directory = getAssetDirectory(record.AssetCategory)
        local base = type(directory) == "table"
            and number(directory.EarningRate, 0)
            or 0

        local scale = math.max(number(record.AssetScale, 1), 0)
        local scaleFactor

        if scale <= 5 then
            scaleFactor = scale ^ 1.85
        else
            scaleFactor = (scale / 5) ^ 1.2 * 19.637875755794113
        end

        local mutationMultiplier = 1

        -- Best-effort mutation fallback. The real module is preferred.
        if Assets and type(Assets.Mutations) == "table" then
            -- Do not guess unknown mutation multipliers.
            -- Keeping this at 1 is safer than incorrectly ranking an egg.
        end

        return math.max(0, math.round(base * scaleFactor * mutationMultiplier))
    end

    local function displayAnimalName(record, directory)
        -- The supplied game's EggRecords uses mutation-aware display names.
        -- Try its own helper first.
        local EggRecords = tryGetModule({"Shared", "Util", "EggRecords"})

        if EggRecords and type(EggRecords.DisplayName) == "function" then
            local ok, name = pcall(function()
                return EggRecords.DisplayName(record)
            end)

            if ok and type(name) == "string" and #name > 0 then
                return name
            end
        end

        if type(directory) == "table" then
            return tostring(
                directory.DisplayName
                or directory.Name
                or record.AssetCategory
                or "Unknown Beast"
            )
        end

        return tostring(record.AssetCategory or "Unknown Beast")
    end

    local function getEggPosition(record)
        if typeof(record.BoundsCFrame) == "CFrame" then
            return record.BoundsCFrame
        end

        if typeof(record.BottomCFrame) == "CFrame" then
            return record.BottomCFrame
        end

        return nil
    end

    local function isCandidate(record)
        if type(record) ~= "table" then
            return false
        end

        if type(record.Uid) ~= "string" or record.Uid == "" then
            return false
        end

        if type(record.AssetCategory) ~= "string" or record.AssetCategory == "" then
            return false
        end

        local stateName = tostring(record.State or "")
        if next(CONFIG.VALID_STATES) ~= nil and not CONFIG.VALID_STATES[stateName] then
            return false
        end

        if record.CarrierUserId ~= nil then
            return false
        end

        return getEggPosition(record) ~= nil
    end

    local function enrichRecord(record)
        local directory = getAssetDirectory(record.AssetCategory)

        local info = {
            record = record,
            uid = record.Uid,
            category = record.AssetCategory,
            name = displayAnimalName(record, directory),
            rarity = getRarityName(directory),
            rarityRank = getRarityRank(directory),
            scale = number(record.AssetScale, 1),
            weight = 0,
            perSecond = 0,
            position = getEggPosition(record),
            mutations = type(record.Mutations) == "table" and table.clone(record.Mutations) or {},
        }

        info.weight = calculateWeight(record, directory)
        info.perSecond = calculateRate(record)

        return info
    end

    local function isBetter(a, b)
        if not b then
            return true
        end

        if a.perSecond ~= b.perSecond then
            return a.perSecond > b.perSecond
        end

        if a.weight ~= b.weight then
            return a.weight > b.weight
        end

        if a.rarityRank ~= b.rarityRank then
            return a.rarityRank > b.rarityRank
        end

        return a.scale > b.scale
    end

    --// UI
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local oldGui = playerGui:FindFirstChild(CONFIG.UI_NAME)
    if oldGui then
        oldGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = CONFIG.UI_NAME
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(1, 0.5)
    main.Position = UDim2.new(1, -18, 0.5, 0)
    main.Size = UDim2.fromOffset(360, 300)
    main.BackgroundTransparency = 0.08
    main.BorderSizePixel = 0
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = main

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.Parent = main

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 21
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🥚  EGG HUNTER"
    title.Parent = main

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(0, 37)
    status.Size = UDim2.new(1, 0, 0, 24)
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "Ready"
    status.Parent = main

    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Position = UDim2.fromOffset(0, 68)
    info.Size = UDim2.new(1, 0, 0, 118)
    info.Font = Enum.Font.Gotham
    info.TextSize = 14
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Text = "No egg scanned yet."
    info.Parent = main

    local takeButton = Instance.new("TextButton")
    takeButton.Name = "TakeBestEgg"
    takeButton.Position = UDim2.new(0, 0, 1, -48)
    takeButton.Size = UDim2.new(0.62, -5, 0, 42)
    takeButton.Font = Enum.Font.GothamBold
    takeButton.TextSize = 15
    takeButton.Text = "TAKE BEST EGG"
    takeButton.AutoButtonColor = true
    takeButton.Parent = main

    local takeCorner = Instance.new("UICorner")
    takeCorner.CornerRadius = UDim.new(0, 10)
    takeCorner.Parent = takeButton

    local refreshButton = Instance.new("TextButton")
    refreshButton.Name = "Refresh"
    refreshButton.Position = UDim2.new(0.62, 5, 1, -48)
    refreshButton.Size = UDim2.new(0.38, -5, 0, 42)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 14
    refreshButton.Text = "REFRESH"
    refreshButton.AutoButtonColor = true
    refreshButton.Parent = main

    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 10)
    refreshCorner.Parent = refreshButton

    local function formatNumber(n)
        n = number(n, 0)

        if math.abs(n) >= 1e15 then
            return string.format("%.2fQ", n / 1e15)
        elseif math.abs(n) >= 1e12 then
            return string.format("%.2fT", n / 1e12)
        elseif math.abs(n) >= 1e9 then
            return string.format("%.2fB", n / 1e9)
        elseif math.abs(n) >= 1e6 then
            return string.format("%.2fM", n / 1e6)
        elseif math.abs(n) >= 1e3 then
            return string.format("%.2fK", n / 1e3)
        end

        return tostring(math.floor(n + 0.5))
    end

    local function formatMutations(mutations)
        if type(mutations) ~= "table" or #mutations == 0 then
            return "None"
        end

        local out = {}
        for i = 1, math.min(#mutations, 6) do
            out[#out + 1] = tostring(mutations[i])
        end

        if #mutations > 6 then
            out[#out + 1] = "..."
        end

        return table.concat(out, ", ")
    end

    local function renderInfo(best, count)
        if not best then
            info.Text = "No pickup-ready eggs found."
            return
        end

        info.Text = table.concat({
            "🐾 Beast: " .. tostring(best.name),
            "⭐ Rarity: " .. tostring(best.rarity),
            "📏 Size: " .. string.format("%.3fx  |  %.2f kg", best.scale, best.weight),
            "💰 Per Second: $" .. formatNumber(best.perSecond) .. "/s",
            "🧬 Mutations: " .. formatMutations(best.mutations),
            "📍 Area: " .. tostring(best.record.AreaId or "Unknown"),
            "",
            "Scanned: " .. tostring(count) .. " pickup-ready eggs",
        }, "\n")
    end

    local function setStatus(text)
        status.Text = tostring(text)
    end

    local function scanBest()
        if state.busy then
            return false, "Busy"
        end

        if not remotesReady or not SnapshotRemote then
            setStatus("Waiting for EggWorld remotes...")
            return false, "EggWorld remotes not ready"
        end

        setStatus("Scanning field eggs...")

        local ok, payload, err = invokeWithTimeout(SnapshotRemote)

        if not ok then
            setStatus("Snapshot failed: " .. tostring(err))
            return false, err
        end

        local snapshot
        if payload and payload[1] ~= nil then
            snapshot = payload[1]
        end

        if type(snapshot) ~= "table" then
            setStatus("Invalid snapshot.")
            return false, "Invalid snapshot"
        end

        local records = snapshot.Records
        if type(records) ~= "table" then
            setStatus("Snapshot has no Records.")
            return false, "No records"
        end

        local best = nil
        local enriched = {}

        -- One linear pass. No nested descendant scans.
        for _, record in ipairs(records) do
            if isCandidate(record) then
                local candidate = enrichRecord(record)
                enriched[#enriched + 1] = candidate

                if isBetter(candidate, best) then
                    best = candidate
                end
            end
        end

        state.cachedRecords = enriched
        state.cachedBest = best
        state.generation += 1

        renderInfo(best, #enriched)

        if best then
            setStatus("Best egg found • ready to take")
        else
            setStatus("No pickup-ready egg found")
        end

        return best ~= nil, best
    end

    local function findRecordStillPresent(uid)
        if not remotesReady or not SnapshotRemote then
            return nil
        end

        local ok, payload = invokeWithTimeout(SnapshotRemote)

        if not ok or not payload or type(payload[1]) ~= "table" then
            return nil
        end

        local snapshot = payload[1]
        local records = snapshot.Records

        if type(records) ~= "table" then
            return nil
        end

        for _, record in ipairs(records) do
            if type(record) == "table" and record.Uid == uid and isCandidate(record) then
                return enrichRecord(record)
            end
        end

        return nil
    end

    local function takeBest()
        if state.busy then
            return
        end

        if os.clock() - state.lastAction < CONFIG.ACTION_COOLDOWN then
            return
        end

        state.lastAction = os.clock()
        state.busy = true
        takeButton.Text = "WORKING..."

        local ok, best = scanBest()

        if not ok or not best then
            takeButton.Text = "TAKE BEST EGG"
            state.busy = false
            return
        end

        -- Revalidate immediately before teleporting. This prevents taking
        -- a stale cached UID after another player already claimed it.
        setStatus("Rechecking " .. tostring(best.name) .. "...")

        local fresh = findRecordStillPresent(best.uid)
        if not fresh then
            setStatus("Egg changed — rescanning...")
            scanBest()
            takeButton.Text = "TAKE BEST EGG"
            state.busy = false
            return
        end

        best = fresh
        state.cachedBest = best
        renderInfo(best, #state.cachedRecords)

        local originalCFrame = getCharacter():GetPivot()
        local lobbyCFrame = getLobbyCFrame()

        setStatus("Teleporting to best egg...")
        local tpOk, tpErr = teleportCharacter(best.position)

        if not tpOk then
            setStatus("Teleport failed: " .. tostring(tpErr))
            takeButton.Text = "TAKE BEST EGG"
            state.busy = false
            return
        end

        task.wait(CONFIG.AFTER_TELEPORT_DELAY)

        setStatus("Requesting egg pickup...")

        -- Exact request shape from the supplied map:
        -- { Uid = <string>, FirstAreaSlotKey = <optional string> }
        local carryOk, result, carryErr = invokeWithTimeout(
            CarryRemote,
            {
                Uid = best.uid,
                FirstAreaSlotKey = nil,
            }
        )

        local success = false
        local message = nil

        if carryOk and result then
            success = result[1] == true
            message = result[2]
        elseif not carryOk then
            message = carryErr
        end

        if success then
            setStatus("Egg picked up • returning to lobby...")
            task.wait(CONFIG.AFTER_CARRY_DELAY)

            -- Return to the actual SpawnLocation/lobby detected in the map.
            local returnOk, returnErr = teleportCharacter(lobbyCFrame)

            if returnOk then
                setStatus("SUCCESS • " .. tostring(best.name) .. " secured")
            else
                -- Emergency fallback to the exact position we started from.
                pcall(function()
                    getCharacter():PivotTo(originalCFrame)
                end)

                setStatus("Egg claimed • lobby return fallback used: " .. tostring(returnErr))
            end
        else
            -- Never repeatedly fire the remote. The server is authoritative.
            -- Restore the player to the lobby if the request was rejected.
            setStatus("Pickup rejected: " .. tostring(message or "unknown"))
            task.wait(0.05)

            local returnOk = teleportCharacter(lobbyCFrame)

            if not returnOk then
                pcall(function()
                    getCharacter():PivotTo(originalCFrame)
                end)
            end
        end

        takeButton.Text = "TAKE BEST EGG"
        state.busy = false

        -- Refresh once after the operation, not every frame.
        task.defer(function()
            if not state.busy then
                scanBest()
            end
        end)
    end

    refreshButton.MouseButton1Click:Connect(function()
        if state.busy then
            return
        end

        if not remotesReady then
            setStatus("Retrying EggWorld connection...")
            task.spawn(function()
                if resolveRemotes(8) then
                    setStatus("Connected • scanning...")
                    scanBest()
                else
                    setStatus("EggWorld remotes still unavailable")
                end
            end)
        else
            scanBest()
        end
    end)

    takeButton.MouseButton1Click:Connect(takeBest)

    -- Resolve the remotes after the UI has already been created.
    -- This guarantees the panel is visible even if replication is late.
    task.spawn(function()
        setStatus("Connecting to EggWorld...")

        local ready = resolveRemotes(15)
        if not ready then
            warn("[EggHunter V2] EggWorld remotes are not currently replicated; UI stays active.")
            setStatus("EggWorld remotes not found • press REFRESH to retry")
            return
        end

        setStatus("Connected • scanning...")
        task.defer(function()
            scanBest()
        end)
    end)

    print("================================")
    print("EGG HUNTER FIXED V2 INITIALIZED")
    print("Remote resolver: WAIT + RETRY")
    print("Snapshot: RF/EggWorld/AskFieldEggSnapshot")
    print("Carry:    RF/EggWorld/AskFieldEggCarry")
    print("Ranking: $/s > weight > rarity")
    print("Performance mode: LOW-SCAN")
    print("================================")
end)
