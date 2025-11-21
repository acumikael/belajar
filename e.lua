-- ======================================================
-- CONFIGURATION (ISI DISINI)
-- ======================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421435065220468779/gnBnih3p73YbLcUggL-fk2HzEKgfTyYPp0UHiinW8J8---3bs_J8WvUymWT2Vgef5_fE" -- Ganti dengan URL Webhook Discord Anda
local DEFAULT_TARGET = 8 -- Jumlah default target

-- ======================================================
-- SETUP SERVICES
-- ======================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Fungsi Request (Support Delta/Fluxus/Arceus)
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- ======================================================
-- UI SETUP
-- ======================================================
if player.PlayerGui:FindFirstChild("GardenNotifierGui") then
    player.PlayerGui.GardenNotifierGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GardenNotifierGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- FRAME UTAMA
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.85, 0, 0.5, 0) -- Posisi di Kanan Layar
mainFrame.Size = UDim2.new(0, 220, 0, 250)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 128)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true -- Bisa digeser

-- JUDUL
local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = mainFrame
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 128)
titleLabel.Text = "GARDEN NOTIFIER"
titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14

-- INPUT TARGET (Textbox)
local targetLabel = Instance.new("TextLabel")
targetLabel.Parent = mainFrame
targetLabel.Position = UDim2.new(0, 10, 0, 40)
targetLabel.Size = UDim2.new(0.6, 0, 0, 25)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Target Jumlah:"
targetLabel.TextColor3 = Color3.new(1,1,1)
targetLabel.TextXAlignment = Enum.TextXAlignment.Left

local targetInput = Instance.new("TextBox")
targetInput.Parent = mainFrame
targetInput.Position = UDim2.new(0.65, 0, 0, 40)
targetInput.Size = UDim2.new(0.3, 0, 0, 25)
targetInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
targetInput.TextColor3 = Color3.new(1,1,1)
targetInput.Text = tostring(DEFAULT_TARGET) -- Default 8
targetInput.Font = Enum.Font.Code
targetInput.TextSize = 14

-- STATUS LABEL
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = mainFrame
statusLabel.Position = UDim2.new(0, 10, 0, 70)
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
statusLabel.Text = "Status: Monitoring..."
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- LIST HASIL (Scrollable)
local resultFrame = Instance.new("ScrollingFrame")
resultFrame.Parent = mainFrame
resultFrame.Position = UDim2.new(0, 10, 0, 100)
resultFrame.Size = UDim2.new(1, -20, 1, -110)
resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
resultFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local resultText = Instance.new("TextLabel")
resultText.Parent = resultFrame
resultText.Size = UDim2.new(1, 0, 1, 0)
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Color3.new(1,1,1)
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.Text = "Menunggu data..."
resultText.RichText = true

-- ======================================================
-- LOGIC FUNCTIONS
-- ======================================================

local hasSentWebhook = false -- Flag supaya tidak spam
local lastTotal = 0

local function cleanText(str)
    local clean = string.gsub(str, "<.->", "") 
    clean = string.match(clean, "^%s*(.-)%s*$")
    return clean
end

-- Fungsi Kirim Webhook
local function sendDiscordWebhook(dataList, totalCount)
    if WEBHOOK_URL == "MASUKAN_WEBHOOK_URL_DISINI" or WEBHOOK_URL == "" then
        statusLabel.Text = "Error: Webhook URL kosong!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end

    statusLabel.Text = "Mengirim ke Discord..."
    
    -- Format pesan untuk Discord
    local description = "**Total Detected: " .. totalCount .. "**\n\n"
    for name, count in pairs(dataList) do
        description = description .. "• " .. name .. " (x" .. count .. ")\n"
    end

    local payload = {
        content = "@here Panen Siap! Target Tercapai.",
        embeds = {{
            title = "🌱 Grow a Garden - Egg Notification",
            description = description,
            color = 65280, -- Warna Hijau
            footer = { text = "Auto Notifier Script" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    local success, response = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success then
        statusLabel.Text = "Terkirim ke Discord! ✅"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        statusLabel.Text = "Gagal kirim Webhook ❌"
        statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end

-- Fungsi Utama Scan
local function scanAndNotify()
    -- Ambil Target dari Input Box
    local targetLimit = tonumber(targetInput.Text) or 8
    
    local f1 = Workspace:FindFirstChild("Farm")
    local f2 = f1 and f1:FindFirstChild("Farm")
    local f3 = f2 and f2:FindFirstChild("Important")
    local folder = f3 and (f3:FindFirstChild("Objects_Physical") or f3:FindFirstChild("Objects-Physical"))

    if not folder then
        resultText.Text = "Folder tidak ditemukan!"
        return
    end

    local counts = {}
    local totalFound = 0

    -- Scan Logic
    for _, item in ipairs(folder:GetDescendants()) do
        if item:IsA("TextLabel") and item.Parent:IsA("BillboardGui") then
            local rawText = item.Text
            if string.find(rawText, "<font") or string.len(rawText) > 2 then
                local name = cleanText(rawText)
                
                -- Bersihkan enter/newline yang mengganggu di screenshot
                name = string.gsub(name, "\n", " ") 
                -- Ambil kata kunci penting saja (misal nama hewan) kalau string kepanjangan
                -- (Opsional, saat ini kita ambil full string yang sudah dibersihkan)
                
                if name ~= "" and not tonumber(name) and name ~= "..." then
                    totalFound = totalFound + 1
                    counts[name] = (counts[name] or 0) + 1
                end
            end
        end
    end

    -- Update Tampilan GUI
    local displayText = ""
    for name, count in pairs(counts) do
        displayText = displayText .. "• " .. name .. ": <b>" .. count .. "</b>\n\n"
    end
    resultText.Text = displayText
    
    -- Sesuaikan ukuran scroll
    resultFrame.CanvasSize = UDim2.new(0, 0, 0, totalFound * 30)

    -- LOGIC NOTIFIKASI
    if totalFound >= targetLimit then
        -- Jika target tercapai DAN belum pernah kirim (untuk sesi ini)
        if not hasSentWebhook then
            sendDiscordWebhook(counts, totalFound)
            hasSentWebhook = true -- Kunci supaya tidak spam
        end
    else
        -- Jika jumlah turun di bawah target (misal sudah dipanen), reset kunci
        if hasSentWebhook then
            hasSentWebhook = false
            statusLabel.Text = "Reset. Menunggu target..."
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            statusLabel.Text = "Menunggu... (" .. totalFound .. "/" .. targetLimit .. ")"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    end
end

-- Loop setiap 2 detik
task.spawn(function()
    while true do
        scanAndNotify()
        task.wait(2)
    end
end)
