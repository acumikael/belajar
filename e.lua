-- ======================================================
-- CONFIGURATION (ISI DISINI)
-- ======================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421435065220468779/gnBnih3p73YbLcUggL-fk2HzEKgfTyYPp0UHiinW8J8---3bs_J8WvUymWT2Vgef5_fE" -- Ganti dengan URL Webhook Discord Anda
local DEFAULT_TARGET = 69 -- Jumlah default target

-- ======================================================
-- SERVICES & VARIABLES
-- ======================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Fungsi Request (Support Delta/Fluxus/Arceus)
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- STATE VARIABLES
local isRunning = false
local sessionStartTime = 0
local batchStartTime = 0
local totalHatched = 0
local lastBatchDuration = "N/A"
local hasSentWebhook = false

-- ======================================================
-- UI SETUP
-- ======================================================
if player.PlayerGui:FindFirstChild("GardenManagerPro") then
    player.PlayerGui.GardenManagerPro:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GardenManagerPro"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- FRAME UTAMA
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 240, 0, 320) -- Diperbesar untuk stats
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 128)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true

-- JUDUL
local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
titleLabel.Text = "GARDEN MANAGER PRO"
titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14

-- AREA INPUT TARGET
local targetLabel = Instance.new("TextLabel")
targetLabel.Parent = mainFrame
targetLabel.Position = UDim2.new(0, 10, 0, 40)
targetLabel.Size = UDim2.new(0.5, 0, 0, 25)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target Batch:"
targetLabel.TextColor3 = Color3.new(1,1,1)
targetLabel.TextXAlignment = Enum.TextXAlignment.Left

local targetInput = Instance.new("TextBox")
targetInput.Parent = mainFrame
targetInput.Position = UDim2.new(0.6, 0, 0, 40)
targetInput.Size = UDim2.new(0.35, 0, 0, 25)
targetInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
targetInput.TextColor3 = Color3.new(1,1,1)
targetInput.Text = tostring(DEFAULT_TARGET)
targetInput.Font = Enum.Font.Code
targetInput.TextSize = 14

-- TOMBOL START/STOP
local startBtn = Instance.new("TextButton")
startBtn.Parent = mainFrame
startBtn.Position = UDim2.new(0, 10, 0, 75)
startBtn.Size = UDim2.new(1, -20, 0, 30)
startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Hijau
startBtn.Text = "START TRACKING"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14

-- STATISTIK DISPLAY
local statsFrame = Instance.new("Frame")
statsFrame.Parent = mainFrame
statsFrame.Position = UDim2.new(0, 10, 0, 115)
statsFrame.Size = UDim2.new(1, -20, 0, 60)
statsFrame.BackgroundTransparency = 1

local function createStatLabel(name, val, yPos)
    local l = Instance.new("TextLabel")
    l.Parent = statsFrame
    l.Position = UDim2.new(0, 0, 0, yPos)
    l.Size = UDim2.new(1, 0, 0, 15)
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.Text = name .. ": " .. val
    return l
end

local runtimeLabel = createStatLabel("Runtime", "00:00:00", 0)
local hatchedLabel = createStatLabel("Total Hatched", "0", 15)
local lastBatchLabel = createStatLabel("Last Batch", "N/A", 30)
local currentStatusLabel = createStatLabel("Status", "Idle", 45)
currentStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)

-- LIST HASIL (Scrollable)
local resultFrame = Instance.new("ScrollingFrame")
resultFrame.Parent = mainFrame
resultFrame.Position = UDim2.new(0, 10, 0, 185)
resultFrame.Size = UDim2.new(1, -20, 1, -195)
resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
resultFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local resultText = Instance.new("TextLabel")
resultText.Parent = resultFrame
resultText.Size = UDim2.new(1, 0, 1, 0)
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Color3.new(1,1,1)
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.Text = "Menunggu Start..."
resultText.RichText = true

-- ======================================================
-- LOGIC FUNCTIONS
-- ======================================================

-- Format Detik ke Jam:Menit:Detik
local function formatTime(seconds)
    if seconds <= 0 then return "00:00:00" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Format Detik ke Menit:Detik (Untuk Batch)
local function formatBatchTime(seconds)
    if seconds <= 0 then return "0s" end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    if m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

local function cleanText(str)
    local clean = string.gsub(str, "<.->", "") 
    clean = string.match(clean, "^%s*(.-)%s*$")
    return clean
end

-- Update Webhook
local function sendDiscordWebhook(dataList, totalCount)
    if WEBHOOK_URL == "MASUKAN_WEBHOOK_URL_DISINI" or WEBHOOK_URL == "" then
        currentStatusLabel.Text = "Status: URL Webhook Error!"
        return
    end

    currentStatusLabel.Text = "Status: Mengirim Webhook..."
    
    local runTimeStr = formatTime(tick() - sessionStartTime)
    
    local description = "**Batch Completed!**\n"
    description = description .. "📦 **Collected:** " .. totalCount .. "\n"
    description = description .. "⏱️ **Batch Time:** " .. lastBatchDuration .. "\n"
    description = description .. "⏳ **Total Runtime:** " .. runTimeStr .. "\n"
    description = description .. "🥚 **Total Session:** " .. totalHatched .. "\n\n"
    description = description .. "**Isi Batch:**\n"
    
    for name, count in pairs(dataList) do
        description = description .. "• " .. name .. " (x" .. count .. ")\n"
    end

    local payload = {
        content = "",
        embeds = {{
            title = "🌱 Garden Report - " .. player.Name,
            description = description,
            color = 65280,
            footer = { text = "Garden Manager Pro" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    currentStatusLabel.Text = "Status: Terkirim! Menunggu Reset..."
end

-- ======================================================
-- BUTTON LOGIC
-- ======================================================
startBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    
    if isRunning then
        -- RESET START
        startBtn.Text = "STOP / RESET"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Merah
        
        sessionStartTime = tick()
        batchStartTime = tick()
        totalHatched = 0
        lastBatchDuration = "-"
        hasSentWebhook = false
        
        hatchedLabel.Text = "Total Hatched: 0"
        lastBatchLabel.Text = "Last Batch: -"
        currentStatusLabel.Text = "Status: Running..."
    else
        -- STOP
        startBtn.Text = "START TRACKING"
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0) -- Hijau
        currentStatusLabel.Text = "Status: Paused"
    end
end)

-- ======================================================
-- MAIN LOOP
-- ======================================================
local function scanAndNotify()
    -- Update Runtime Display setiap saat jika running
    if isRunning then
        local currentRun = tick() - sessionStartTime
        runtimeLabel.Text = "Runtime: " .. formatTime(currentRun)
    end

    -- Target Input Logic
    local targetLimit = tonumber(targetInput.Text) or 8
    
    -- Mencari Folder
    local f1 = Workspace:FindFirstChild("Farm")
    local f2 = f1 and f1:FindFirstChild("Farm")
    local f3 = f2 and f2:FindFirstChild("Important")
    local folder = f3 and (f3:FindFirstChild("Objects_Physical") or f3:FindFirstChild("Objects-Physical"))

    if not folder then
        resultText.Text = "Mencari Folder..."
        return
    end

    local counts = {}
    local totalFound = 0

    -- Scanning TextLabels
    for _, item in ipairs(folder:GetDescendants()) do
        if item:IsA("TextLabel") and item.Parent:IsA("BillboardGui") then
            local rawText = item.Text
            if string.find(rawText, "<font") or string.len(rawText) > 2 then
                local name = cleanText(rawText)
                name = string.gsub(name, "\n", " ") 
                
                if name ~= "" and not tonumber(name) and name ~= "..." then
                    totalFound = totalFound + 1
                    counts[name] = (counts[name] or 0) + 1
                end
            end
        end
    end

    -- Update List Teks GUI
    local displayText = ""
    for name, count in pairs(counts) do
        displayText = displayText .. "• " .. name .. ": <b>" .. count .. "</b>\n"
    end
    
    if not isRunning then
        resultText.Text = "--- PAUSED ---\n" .. displayText
    else
        resultText.Text = displayText
    end
    
    resultFrame.CanvasSize = UDim2.new(0, 0, 0, totalFound * 20)

    -- LOGIC STATISTIK & WEBHOOK (Hanya jika Running)
    if isRunning then
        if totalFound >= targetLimit then
            -- TARGET TERCAPAI
            if not hasSentWebhook then
                -- Hitung durasi batch ini
                local durationSecs = tick() - batchStartTime
                lastBatchDuration = formatBatchTime(durationSecs)
                
                -- Update Stats UI
                lastBatchLabel.Text = "Last Batch: " .. lastBatchDuration
                totalHatched = totalHatched + totalFound
                hatchedLabel.Text = "Total Hatched: " .. totalHatched
                
                -- Kirim Webhook
                sendDiscordWebhook(counts, totalFound)
                
                hasSentWebhook = true -- Kunci
            end
        else
            -- LOGIC RESET BATCH
            -- Jika jumlah telur turun drastis (misal di bawah setengah target), kita anggap user sudah panen (Hatch)
            -- Maka kita reset timer untuk batch berikutnya
            if hasSentWebhook and totalFound < (targetLimit / 2) then
                hasSentWebhook = false
                batchStartTime = tick() -- Mulai hitung waktu batch baru
                currentStatusLabel.Text = "Status: Batch Reset. Timer baru dimulai."
                currentStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            elseif not hasSentWebhook then
                currentStatusLabel.Text = "Status: Mengisi (" .. totalFound .. "/" .. targetLimit .. ")"
                currentStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            end
        end
    end
end

-- Loop System
task.spawn(function()
    while true do
        scanAndNotify()
        task.wait(1)
    end
end)
