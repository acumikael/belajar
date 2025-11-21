-- ======================================================
-- CONFIGURATION (ISI DISINI)
-- ======================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421435065220468779/gnBnih3p73YbLcUggL-fk2HzEKgfTyYPp0UHiinW8J8---3bs_J8WvUymWT2Vgef5_fE" -- Ganti URL Webhook
local DEFAULT_TARGET = 8 

-- ======================================================
-- SERVICES
-- ======================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- STATE
local isRunning = false
local sessionStartTime = 0
local batchStartTime = 0
local totalHatched = 0
local lastBatchDuration = "0s"
local hasSentWebhook = false

-- ======================================================
-- UI SETUP
-- ======================================================
if player.PlayerGui:FindFirstChild("GardenUltimate") then
    player.PlayerGui.GardenUltimate:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GardenUltimate"
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255) -- Cyan Border
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true

-- TITLE
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
title.Text = "GARDEN MANAGER ULTIMATE"
title.TextColor3 = Color3.new(0,0,0)
title.Font = Enum.Font.GothamBlack
title.TextSize = 14

-- INPUT
local targetBox = Instance.new("TextBox")
targetBox.Parent = mainFrame
targetBox.Position = UDim2.new(0.6, 0, 0, 40)
targetBox.Size = UDim2.new(0.35, 0, 0, 25)
targetBox.Text = tostring(DEFAULT_TARGET)
targetBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
targetBox.TextColor3 = Color3.new(1,1,1)
targetBox.Font = Enum.Font.GothamBold
targetBox.TextSize = 14

local labelTarget = Instance.new("TextLabel")
labelTarget.Parent = mainFrame
labelTarget.Position = UDim2.new(0, 10, 0, 40)
labelTarget.Size = UDim2.new(0.5, 0, 0, 25)
labelTarget.BackgroundTransparency = 1
labelTarget.Text = "Target Batch:"
labelTarget.TextColor3 = Color3.new(1,1,1)
labelTarget.TextXAlignment = Enum.TextXAlignment.Left

-- BUTTON
local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = mainFrame
toggleBtn.Position = UDim2.new(0, 10, 0, 75)
toggleBtn.Size = UDim2.new(1, -20, 0, 35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
toggleBtn.Text = "START / RESUME"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.TextColor3 = Color3.new(1,1,1)

-- STATS LABELS
local statsContainer = Instance.new("Frame")
statsContainer.Parent = mainFrame
statsContainer.Position = UDim2.new(0, 10, 0, 120)
statsContainer.Size = UDim2.new(1, -20, 0, 80)
statsContainer.BackgroundTransparency = 1

local function makeLabel(txt, y)
    local l = Instance.new("TextLabel")
    l.Parent = statsContainer
    l.Position = UDim2.new(0,0,0,y)
    l.Size = UDim2.new(1,0,0,15)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200,200,200)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.Text = txt
    return l
end

local lblRuntime = makeLabel("Runtime: 00:00:00", 0)
local lblHatched = makeLabel("Total Hatched: 0", 15)
local lblLastBatch = makeLabel("Last Batch Time: -", 30)
local lblStatus = makeLabel("Status: IDLE", 45)
lblStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
local lblDebug = makeLabel("Debug: -", 60) -- Tambahan untuk cek error
lblDebug.TextColor3 = Color3.fromRGB(100, 100, 100)

-- RESULT LIST
local scrollList = Instance.new("ScrollingFrame")
scrollList.Parent = mainFrame
scrollList.Position = UDim2.new(0, 10, 0, 210)
scrollList.Size = UDim2.new(1, -20, 1, -220)
scrollList.BackgroundColor3 = Color3.fromRGB(20,20,20)
scrollList.CanvasSize = UDim2.new(0,0,0,0)

local resultText = Instance.new("TextLabel")
resultText.Parent = scrollList
resultText.Size = UDim2.new(1,0,1,0)
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Color3.new(1,1,1)
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.RichText = true
resultText.Text = "Tekan START..."

-- ======================================================
-- FUNCTIONS
-- ======================================================

local function formatTime(s)
    if s <= 0 then return "00:00:00" end
    return string.format("%02d:%02d:%02d", s/3600, (s%3600)/60, s%60)
end

local function cleanText(str)
    local clean = string.gsub(str, "<.->", "")
    clean = string.match(clean, "^%s*(.-)%s*$")
    return clean
end

local function sendWebhook(dataList, count)
    if not WEBHOOK_URL or WEBHOOK_URL == "MASUKAN_WEBHOOK_URL_DISINI" then return end
    
    lblStatus.Text = "Status: Mengirim Webhook..."
    
    local runtimeStr = formatTime(tick() - sessionStartTime)
    
    local contentStr = ""
    for name, qty in pairs(dataList) do
        contentStr = contentStr .. "• **" .. name .. "** x" .. qty .. "\n"
    end
    
    local embedData = {
        {
            ["title"] = "🌱 Garden Harvest Report",
            ["description"] = "Batch Target Tercapai!",
            ["color"] = 65280, -- Hijau
            ["fields"] = {
                { ["name"] = "⏱️ Runtime", ["value"] = runtimeStr, ["inline"] = true },
                { ["name"] = "🥚 Total Hatched", ["value"] = tostring(totalHatched), ["inline"] = true },
                { ["name"] = "⚡ Last Batch", ["value"] = lastBatchDuration, ["inline"] = true },
                { ["name"] = "📦 Isi Batch Ini", ["value"] = contentStr, ["inline"] = false }
            },
            ["footer"] = { ["text"] = "Garden Ultimate Script" },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }

    local payload = HttpService:JSONEncode({
        ["embeds"] = embedData
    })

    request({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = payload
    })
    
    lblStatus.Text = "Status: Webhook Terkirim!"
end

-- ======================================================
-- CORE LOGIC (SCANNER)
-- ======================================================

local function scanGarden()
    if not isRunning then return end
    
    -- Update Runtime
    lblRuntime.Text = "Runtime: " .. formatTime(tick() - sessionStartTime)
    
    local target = tonumber(targetBox.Text) or 8
    local foundCounts = {}
    local foundTotal = 0
    
    -- SEARCH LOGIC YANG DIPERBAIKI (LEBIH LUAS)
    -- Kita mencari di workspace.Farm.Farm (Induk utama)
    -- Jika tidak ketemu, cari di seluruh workspace (Backup)
    local searchRoot = workspace:FindFirstChild("Farm") and workspace.Farm:FindFirstChild("Farm") or workspace
    
    -- Debugging info
    local scannedObjects = 0
    
    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            scannedObjects = scannedObjects + 1
            
            -- Cek 1: Apakah teksnya mengandung HTML (ESP)
            -- Cek 2: Apakah induknya BillboardGui (Text Melayang)
            local isESP = false
            
            if string.find(obj.Text, "<font") then
                isESP = true
            elseif obj:FindFirstAncestorWhichIsA("BillboardGui") then
                -- Jika teksnya panjang (bukan cuma angka/titik), anggap ESP
                if string.len(obj.Text) > 2 and not tonumber(obj.Text) then
                    isESP = true
                end
            end
            
            if isESP then
                local raw = cleanText(obj.Text)
                local name = string.gsub(raw, "\n", " ") -- Hapus enter
                
                -- Filter sampah lagi
                if name ~= "" and name ~= "..." and not string.find(name, "Status") then
                    foundTotal = foundTotal + 1
                    foundCounts[name] = (foundCounts[name] or 0) + 1
                end
            end
        end
    end
    
    lblDebug.Text = "Debug: Scan " .. scannedObjects .. " obj, Found " .. foundTotal

    -- UPDATE UI LIST
    local listStr = ""
    for n, c in pairs(foundCounts) do
        listStr = listStr .. "• " .. n .. ": <b>" .. c .. "</b>\n"
    end
    resultText.Text = listStr
    scrollList.CanvasSize = UDim2.new(0,0,0, foundTotal * 20)

    -- LOGIC BATCH & WEBHOOK
    if foundTotal >= target then
        if not hasSentWebhook then
            -- BATCH SELESAI
            local dur = tick() - batchStartTime
            lastBatchDuration = (dur < 60) and math.floor(dur).."s" or math.floor(dur/60).."m "..math.floor(dur%60).."s"
            
            totalHatched = totalHatched + foundTotal
            
            -- Update GUI Stats
            lblLastBatch.Text = "Last Batch Time: " .. lastBatchDuration
            lblHatched.Text = "Total Hatched: " .. totalHatched
            
            sendWebhook(foundCounts, foundTotal)
            hasSentWebhook = true
        end
    else
        -- LOGIC RESET
        if hasSentWebhook and foundTotal < (target / 2) then
            -- Anggap user sudah panen, reset status
            hasSentWebhook = false
            batchStartTime = tick()
            lblStatus.Text = "Status: Reset. New Batch."
        elseif not hasSentWebhook then
            lblStatus.Text = "Status: Mengisi (" .. foundTotal .. "/" .. target .. ")"
        end
    end
end

-- ======================================================
-- BUTTON HANDLER
-- ======================================================
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "PAUSE / STOP"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        -- Jika ini start pertama kali, set timer
        if sessionStartTime == 0 then
            sessionStartTime = tick()
            batchStartTime = tick()
            lblStatus.Text = "Status: Started."
        end
    else
        toggleBtn.Text = "RESUME"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        lblStatus.Text = "Status: Paused."
    end
end)

-- LOOP
task.spawn(function()
    while true do
        scanGarden()
        task.wait(1)
    end
end)
