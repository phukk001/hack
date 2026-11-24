--[[
 DYHUB X 3.0 - COMPACT EDITION
 Skibidi Toilet: Blockade Battlefront
 Client-side prototype

 Aim Assist: local camera only
 Endless Tracker: reads visible game UI
 Drop Tracker: detects visible drop objects
 No guessed RemoteEvents or server manipulation
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Config = {
    Aim = false,
    BossPriority = true,
    AstroPriority = true,
    Visibility = true,

    FOV = 180,
    Smooth = 8,
    ScanRate = 1,

    Tracker = true,
    Performance = true
}

local State = {
    Target = nil,
    Wave = nil,
    BossAlert = "Waiting",
    Drops = 0,
    NPCCount = 0
}

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "DYHUB_X_3"
GUI.ResetOnSpawn = false

local ok = pcall(function()
    GUI.Parent = game:GetService("CoreGui")
end)

if not ok or not GUI.Parent then
    GUI.Parent = Player:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(245, 300)
Main.Position = UDim2.new(0, 25, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Main.BorderSizePixel = 0
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius =
    UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 170, 230)
Stroke.Thickness = 1
Stroke.Parent = Main

local function MakeLabel(text, y, height)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(10, y)
    label.Size = UDim2.new(1, -20, 0, height or 24)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.Text = text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Main
    return label
end

local function MakeButton(text, y, callback)
    local button = Instance.new("TextButton")
    button.Position = UDim2.fromOffset(10, y)
    button.Size = UDim2.new(1, -20, 0, 29)
    button.BackgroundColor3 = Color3.fromRGB(39, 44, 57)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = text
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = Main

    Instance.new("UICorner", button).CornerRadius =
        UDim.new(0, 6)

    button.MouseButton1Click:Connect(callback)
    return button
end

local Header = MakeLabel("DYHUB X  |  ENDLESS", 7, 28)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 15

local AimButton
local BossButton
local AstroButton
local TrackerButton
local PerfButton

AimButton = MakeButton("AIM ASSIST: OFF", 40, function()
    Config.Aim = not Config.Aim
    AimButton.Text = "AIM ASSIST: " ..
        (Config.Aim and "ON" or "OFF")
end)

BossButton = MakeButton("BOSS PRIORITY: ON", 75, function()
    Config.BossPriority = not Config.BossPriority
BossButton.Text = "BOSS PRIORITY: " ..
        (Config.BossPriority and "ON" or "OFF")
end)

AstroButton = MakeButton("ASTRO PRIORITY: ON", 110, function()
    Config.AstroPriority = not Config.AstroPriority
    AstroButton.Text = "ASTRO PRIORITY: " ..
        (Config.AstroPriority and "ON" or "OFF")
end)

TrackerButton = MakeButton("ENDLESS TRACKER: ON", 145, function()
    Config.Tracker = not Config.Tracker
    TrackerButton.Text = "ENDLESS TRACKER: " ..
        (Config.Tracker and "ON" or "OFF")
end)

PerfButton = MakeButton("PERFORMANCE MODE: ON", 180, function()
    Config.Performance = not Config.Performance
    PerfButton.Text = "PERFORMANCE: " ..
        (Config.Performance and "ON" or "OFF")
end)

local WaveLabel = MakeLabel("Wave: Searching...", 218)
local BossLabel = MakeLabel("Boss: Waiting", 241)
local DropLabel = MakeLabel("Visible Drops: 0", 264)
local TargetLabel = MakeLabel("Target: None", 285)

-- FOV Circle
local Circle = Instance.new("Frame")
Circle.Name = "FOV_Circle"
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
Circle.BackgroundTransparency = 1
Circle.Visible = false
Circle.Parent = GUI

Instance.new("UICorner", Circle).CornerRadius =
    UDim.new(1, 0)

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Color3.fromRGB(0, 190, 255)
CircleStroke.Thickness = 1.5
CircleStroke.Parent = Circle

-- Draggable GUI
local dragging = false
local dragStart, startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

-- NPC recognition
local function GetPart(model)
    return model:FindFirstChild("Head")
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function IsValidNPC(model)
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end

    local part = GetPart(model)
    if not part or not part:IsA("BasePart") then return false end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
if humanoid and humanoid.Health <= 0 then return false end

    return true
end

local function GetPriority(model)
    local name = string.lower(model.Name)

    if Config.BossPriority then
        if string.find(name, "boss", 1, true)
        or string.find(name, "professor", 1, true)
        or string.find(name, "g-toilet", 1, true) then
            return 3
        end
    end

    if Config.AstroPriority then
        if string.find(name, "astro", 1, true) then
            return 2
        end
    end

    return 1
end

local function CanSee(model, part)
    if not Config.Visibility then return true end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        Player.Character,
        Camera
    }

    local direction = part.Position - Camera.CFrame.Position
    local result = Workspace:Raycast(
        Camera.CFrame.Position,
        direction,
        params
    )

    return result == nil or result.Instance:IsDescendantOf(model)
end

-- Target scan
local function FindTarget()
    local bestTarget
    local bestPriority = -1
    local bestDistance = Config.FOV

    local center = Camera.ViewportSize / 2

    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and IsValidNPC(model) then
            local part = GetPart(model)

            local position, visible =
                Camera:WorldToViewportPoint(part.Position)

            if visible and position.Z > 0 then
                local distance = (
                    Vector2.new(position.X, position.Y) - center
                ).Magnitude

                if distance <= Config.FOV and CanSee(model, part) then
                    local priority = GetPriority(model)

                    if priority > bestPriority or
                    (priority == bestPriority and distance < bestDistance) then
                        bestTarget = model
                        bestPriority = priority
                        bestDistance = distance
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Endless UI tracker
local function ReadWave()
    local gui = Player:FindFirstChildOfClass("PlayerGui")
    if not gui then return nil end

    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local number = string.match(
                string.lower(obj.Text),
                "wave%s*:?%s*(%d+)"
            )

            if number then
                return tonumber(number)
            end
        end
    end

    return nil
end

-- Visible drop tracker
local function CountDrops()
    local count = 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = string.lower(obj.Name)

        if string.find(name, "flashdrive", 1, true)
        or string.find(name, "toilet token", 1, true)
or string.find(name, "scorching ember", 1, true) then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                count += 1
            end
        end
    end

    return count
end

-- Main update
local lastScan = 0

RunService.RenderStepped:Connect(function(dt)
    local center = Camera.ViewportSize / 2

    Circle.Position = UDim2.fromOffset(center.X, center.Y)
    Circle.Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2)
    Circle.Visible = Config.Aim and Main.Visible

    local interval = Config.Performance and 1.5 or 0.5

    if os.clock() - lastScan >= interval then
        lastScan = os.clock()

        if Config.Aim then
            State.Target = FindTarget()
        else
            State.Target = nil
        end

        if Config.Tracker then
            local wave = ReadWave()

            if wave then
                if State.Wave ~= wave then
                    State.Wave = wave

                    if wave == 90 then
                        State.BossAlert = "HELL WAVE!"
                    elseif wave % 5 == 0 then
                        State.BossAlert = "BOSS WAVE!"
                    else
                        State.BossAlert = "Wave " .. wave
                    end
                end
            end

            State.Drops = CountDrops()
        end
    end

    -- Camera Aim
    if Config.Aim and State.Target and IsValidNPC(State.Target) then
        local part = GetPart(State.Target)

        if part then
            local goal = CFrame.lookAt(
                Camera.CFrame.Position,
                part.Position
            )

            local alpha = 1 - math.exp(-Config.Smooth * dt)
            Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
        end
    end

    -- UI refresh
    WaveLabel.Text = "Wave: " ..
        (State.Wave and tostring(State.Wave) or "Searching...")

    BossLabel.Text = "Alert: " .. State.BossAlert
    DropLabel.Text = "Visible Drops: " .. State.Drops

    TargetLabel.Text = "Target: " ..
        (State.Target and State.Target.Name or "None")
end)

print("[DYHUB X 3.0] Compact Edition loaded")