--[[
    DYHUB X v2.0
    ST:BB - AUTO BUY ONLY
    Astro Weapons + Jetpack + Astro Tech
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ENV = (getgenv and getgenv()) or _G

-- Stop previous instance
if ENV.DYHUB_STOP then
    ENV.DYHUB_STOP = true
end

ENV.DYHUB_STOP = false

local Config = {
    ScanDelay = 2,
    ClickDelay = 3,

    Items = {
        "Astro Blaster",
        "Tazer Gun",
        "Tazer Sniper",
        "Saw Blade",
        "Dual Barrel Blaster",
        "Jetpack",
        "Upgraded Jetpack",
    },

    Research = {
        "Astro Technology",
        "Astro Tech",
    },

    Characters = {
        -- Add exact character names after verifying
        -- their shop labels in ST:BB.
    }
}

local Purchased = {}
local LastClick = {}

local function Normalize(text)
    return string.lower(tostring(text or ""))
end

local function Contains(text, keyword)
    return string.find(
        Normalize(text),
        Normalize(keyword),
        1,
        true
    ) ~= nil
end

local function GetContainerText(obj)
    local result = {}

    local current = obj

    for _ = 1, 5 do
        if not current then break end

        for _, child in ipairs(current:GetDescendants()) do
            if child:IsA("TextLabel")
            or child:IsA("TextButton") then
                table.insert(result, child.Text)
            end
        end

        if current:IsA("TextLabel")
        or current:IsA("TextButton") then
            table.insert(result, current.Text)
        end

        current = current.Parent
    end

    return table.concat(result, " ")
end

local function IsPurchaseButton(obj)
    if not obj:IsA("GuiButton") then
        return false
    end

    local text = Normalize(obj.Text)
    local name = Normalize(obj.Name)

    return text:find("buy", 1, true)
        or text:find("purchase", 1, true)
        or text:find("unlock", 1, true)
        or name:find("buy", 1, true)
        or name:find("purchase", 1, true)
end

local function ClickButton(button, item)
    if not button.Visible then return end

    if Purchased[button] then return end

    local now = os.clock()

    if LastClick[button]
    and now - LastClick[button] < Config.ClickDelay then
        return
    end

    -- Requires an executor that supports firesignal.
    if typeof(firesignal) ~= "function" then
        warn("[DYHUB] firesignal unavailable")
        return
    end

    LastClick[button] = now

    local ok = pcall(function()
        firesignal(button.Activated)
    end)

    if ok then
        print("[DYHUB] Purchase attempted:", item)
    else
        warn("[DYHUB] Could not activate:", item)
    end
end

local function ScanCategory(items)
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if IsPurchaseButton(obj) then
            local context = GetContainerText(obj)

            local owned = Contains(context, "owned")
                or Contains(context, "already purchased")

            if not owned then
                for _, item in ipairs(items) do
                    if Contains(context, item) then
                        ClickButton(obj, item)
                        break
                    end
                end
            end
        end
    end
end

print("[DYHUB X] Auto Buy Started")

while not ENV.DYHUB_STOP do
    pcall(function()
        ScanCategory(Config.Items)
        ScanCategory(Config.Research)
        ScanCategory(Config.Characters)
    end)

    task.wait(Config.ScanDelay)
end

print("[DYHUB X] Auto Buy Stopped")
