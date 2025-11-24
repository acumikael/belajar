--[[
    EGG TRACKER V0.5 REMASTERED (SECURE WEBHOOK + ELEGANT UI)
    Features:
    - Webhook Input via GUI (Anti Leak)
    - Toggle UI Button (Left Side)
    - Lucky Egg Back detection (25s countdown)
    - Elegant Dark Transparent UI
    - Left-aligned Control Buttons
]]--

---------------------------------------------------------
-- SERVICES
---------------------------------------------------------

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

---------------------------------------------------------
-- CONFIG & VARIABLES
---------------------------------------------------------

-- Webhook sekarang variabel kosong, diisi via GUI
local currentWebhookUrl = "" 

local DEFAULT_TARGET = 13
local DEFAULT_BIG_EGG_THRESHOLD = 3
local DEBUG_MODE = false 

---------------------------------------------------------
-- HELPER: SAFE HTTP REQUEST
---------------------------------------------------------

local function performHttpRequest(options)
    local reqFunc = nil
    if type(http_request) == "function" then reqFunc = http_request
    elseif type(request) == "function" then reqFunc = request
    elseif type(syn) == "table" and type(syn.request) == "function" then reqFunc = syn.request
    elseif type(fluxus) == "table" and type(fluxus.request) == "function" then reqFunc = fluxus.request
    elseif type(getgenv) == "function" then
        local env = getgenv()
        if env.request then reqFunc = env.request
        elseif env.http_request then reqFunc = env.http_request end
    end

    if reqFunc then
        return reqFunc(options)
    else
        warn("⚠ FATAL: Executor tidak support request http!")
        return nil
    end
end

---------------------------------------------------------
-- STATE
---------------------------------------------------------

local isRunning = false
local sessionStartTime = 0
local batchStartTime = 0
local totalHatched = 0
local lastBatchDuration = "0s"
local hasSentWebhook = false
local notifiedBigEggs = {}

-- Lucky Egg Back States
local isWaitingForCount = false
local countdownStartTime = 0
local initialEggCount = 0
local luckyEggBackCount = 0
local COUNTDOWN_SECONDS = 25

-- Snapshot data
local snapshotNormalEggs = {}
local snapshotBigEggs = {}
local snapshotTotalReady = 0

local function makeBigEggKey(eggName, petName, kg)
    return string.format("%s|%s|%.1f", eggName, petName, kg)
end

---------------------------------------------------------
-- CLEANUP GUI EXISTING
---------------------------------------------------------

-- Coba hapus dari PlayerGui atau CoreGui (untuk keamanan extra biasanya di CoreGui, tapi PlayerGui lebih stabil)
if player.PlayerGui:FindFirstChild("EggTrackerRemastered") then
    player.PlayerGui.EggTrackerRemastered:Destroy()
end

---------------------------------------------------------
-- THEME CONFIG (ELEGANT DARK)
---------------------------------------------------------

local Theme = {
    Background = Color3.fromRGB(18, 18, 22),
    Accent = Color3.fromRGB(0, 180, 120), -- Green ish
    Secondary = Color3.fromRGB(35, 35, 45),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(180, 180, 180),
    Border = Color3.fromRGB(60, 60, 70),
    Red = Color3.fromRGB(220, 60, 60)
}

---------------------------------------------------------
-- TOGGLE BUTTON (KIRI TENGAH)
---------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggTrackerRemastered"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Parent = screenGui
toggleButton.AnchorPoint = Vector2.new(0, 0.5)
toggleButton.Position = UDim2.new(0, 10, 0.2, 0)
toggleButton.Size = UDim2.new(0, 45, 0, 45)
toggleButton.BackgroundColor3 = Theme.Secondary
toggleButton.Text = "🥚"
toggleButton.TextSize = 22
toggleButton.TextColor3 = Theme.Text
toggleButton.Font = Enum.Font.GothamBold

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Parent = toggleButton
toggleStroke.Color = Theme.Border
toggleStroke.Thickness = 1.5
toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

---------------------------------------------------------
-- MAIN GUI CREATION
---------------------------------------------------------

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.Position = UDim2.new(0, -400, 0.5, 0) -- Hidden initially
mainFrame.Size = UDim2.new(0, 320, 0, 420) -- Sedikit lebih tinggi untuk input webhook
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BackgroundTransparency = 0.1 -- Efek Transparan
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true -- Bisa digeser
mainFrame.Visible = false

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Parent = mainFrame
mainStroke.Color = Theme.Accent
mainStroke.Transparency = 0.6
mainStroke.Thickness = 1

---------------------------------------------------------
-- TITLE BAR
---------------------------------------------------------

local titleBar = Instance.new("Frame")
titleBar.Parent = mainFrame
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Theme.Secondary
titleBar.BackgroundTransparency = 0.5
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Fix corner bawah agar kotak
local bottomCover = Instance.new("Frame")
bottomCover.Parent = titleBar
bottomCover.Size = UDim2.new(1, 0, 0, 10)
bottomCover.Position = UDim2.new(0, 0, 1, -10)
bottomCover.BorderSizePixel = 0
bottomCover.BackgroundColor3 = titleBar.BackgroundColor3
bottomCover.BackgroundTransparency = titleBar.BackgroundTransparency

local titleText = Instance.new("TextLabel")
titleText.Parent = titleBar
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Egg Tracker V0.5"
titleText.TextColor3 = Theme.Text
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Center

---------------------------------------------------------
-- LEFT BUTTONS (CLOSE & DEBUG)
---------------------------------------------------------

-- Close Button (Kiri Paling Ujung)
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(0, 8, 0, 6) -- Posisi Kiri
closeBtn.BackgroundColor3 = Theme.Red
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Debug Button (Sebelah Kiri Close)
local debugToggleBtn = Instance.new("TextButton")
debugToggleBtn.Parent = titleBar
debugToggleBtn.Size = UDim2.new(0, 24, 0, 24)
debugToggleBtn.Position = UDim2.new(0, 38, 0, 6) -- Sebelah tombol close
debugToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
debugToggleBtn.Text = "🛠"
debugToggleBtn.TextColor3 = Color3.new(1,1,1)
debugToggleBtn.Font = Enum.Font.GothamBold
debugToggleBtn.TextSize = 12

local debugCorner = Instance.new("UICorner")
debugCorner.CornerRadius = UDim.new(0, 6)
debugCorner.Parent = debugToggleBtn

---------------------------------------------------------
-- SETTINGS CONTAINER
---------------------------------------------------------

local settingsFrame = Instance.new("Frame")
settingsFrame.Parent = mainFrame
settingsFrame.Position = UDim2.new(0, 10, 0, 46)
settingsFrame.Size = UDim2.new(1, -20, 0, 120)
settingsFrame.BackgroundTransparency = 1

-- Helper Input Creation
local function createInput(parent, title, yPos, defaultVal, isFullWidth)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.Position = UDim2.new(0, 0, 0, yPos)
    label.Size = UDim2.new(isFullWidth and 1 or 0.5, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Theme.TextDim
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 11

    local box = Instance.new("TextBox")
    box.Parent = parent
    if isFullWidth then
        box.Position = UDim2.new(0, 0, 0, yPos + 20)
        box.Size = UDim2.new(1, 0, 0, 26)
    else
        box.Position = UDim2.new(0.6, 0, 0, yPos - 2)
        box.Size = UDim2.new(0.4, 0, 0, 22)
    end
    box.Text = defaultVal
    box.PlaceholderText = "..."
    box.BackgroundColor3 = Theme.Secondary
    box.TextColor3 = Theme.Text
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box
    
    local stroke = Instance.new("UIStroke")
    stroke.Parent = box
    stroke.Color = Theme.Border
    stroke.Transparency = 0.5
    
    return box
end

-- Input Fields
local targetBox = createInput(settingsFrame, "Target Batch:", 4, tostring(DEFAULT_TARGET), false)
local bigEggBox = createInput(settingsFrame, "Big Egg ≥ KG:", 32, tostring(DEFAULT_BIG_EGG_THRESHOLD), false)

-- Webhook Input (Full Width)
local lblWebhook = Instance.new("TextLabel")
lblWebhook.Parent = settingsFrame
lblWebhook.Position = UDim2.new(0, 0, 0, 60)
lblWebhook.Size = UDim2.new(1, 0, 0, 18)
lblWebhook.BackgroundTransparency = 1
lblWebhook.Text = "Discord Webhook URL (Required):"
lblWebhook.TextColor3 = Theme.TextDim
lblWebhook.TextXAlignment = Enum.TextXAlignment.Left
lblWebhook.Font = Enum.Font.Gotham
lblWebhook.TextSize = 11

local webhookBox = Instance.new("TextBox")
webhookBox.Parent = settingsFrame
webhookBox.Position = UDim2.new(0, 0, 0, 80)
webhookBox.Size = UDim2.new(1, 0, 0, 30)
webhookBox.Text = ""
webhookBox.PlaceholderText = "Paste Webhook URL Here..."
webhookBox.PlaceholderColor3 = Color3.fromRGB(100,100,100)
webhookBox.BackgroundColor3 = Theme.Secondary
webhookBox.TextColor3 = Color3.fromRGB(100, 255, 150) -- Text hijau agar beda
webhookBox.Font = Enum.Font.Code
webhookBox.TextSize = 10
webhookBox.ClearTextOnFocus = false
webhookBox.TextWrapped = true

local wbCorner = Instance.new("UICorner")
wbCorner.CornerRadius = UDim.new(0, 6)
wbCorner.Parent = webhookBox

local wbStroke = Instance.new("UIStroke")
wbStroke.Parent = webhookBox
wbStroke.Color = Theme.Border
wbStroke.Transparency = 0.5

-- Update variable saat text berubah
webhookBox.Changed:Connect(function()
    currentWebhookUrl = webhookBox.Text
end)

---------------------------------------------------------
-- START / STOP BUTTON
---------------------------------------------------------

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = mainFrame
toggleBtn.Position = UDim2.new(0, 10, 0, 175)
toggleBtn.Size = UDim2.new(1, -20, 0, 36)
toggleBtn.BackgroundColor3 = Theme.Accent
toggleBtn.Text = "START TRACKING"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.new(1, 1, 1)

local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 8)
toggleBtnCorner.Parent = toggleBtn

local btnGradient = Instance.new("UIGradient")
btnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
})
btnGradient.Parent = toggleBtn

---------------------------------------------------------
-- STATS LABELS
---------------------------------------------------------

local statsContainer = Instance.new("Frame")
statsContainer.Parent = mainFrame
statsContainer.Position = UDim2.new(0, 12, 0, 220)
statsContainer.Size = UDim2.new(1, -24, 0, 100)
statsContainer.BackgroundTransparency = 1

local function makeLabel(txt, y, color)
    local l = Instance.new("TextLabel")
    l.Parent = statsContainer
    l.Position = UDim2.new(0, 0, 0, y)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Theme.TextDim
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.Text = txt
    return l
end

local lblRuntime = makeLabel("Runtime: 00:00:00", 0)
local lblHatched = makeLabel("Total Hatched: 0", 18)
local lblLastBatch = makeLabel("Last Batch Time: -", 36)
local lblLuckyBack = makeLabel("Lucky Egg Back: 0", 54, Color3.fromRGB(255, 200, 80))
local lblStatus = makeLabel("Status: IDLE", 72, Theme.Accent)
local lblDebug = makeLabel("Debug: -", 90, Color3.fromRGB(100, 200, 255))
lblDebug.Visible = false

---------------------------------------------------------
-- RESULT LIST (SCROLLING)
---------------------------------------------------------

local scrollList = Instance.new("ScrollingFrame")
scrollList.Parent = mainFrame
scrollList.Position = UDim2.new(0, 10, 1, -100) -- Posisi relatif bawah
scrollList.Size = UDim2.new(1, -20, 0, 90)
scrollList.BackgroundColor3 = Theme.Secondary
scrollList.BackgroundTransparency = 0.5
scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollList.ScrollBarThickness = 2
scrollList.BorderSizePixel = 0
scrollList.Visible = false

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollList

local resultText = Instance.new("TextLabel")
resultText.Parent = scrollList
resultText.Size = UDim2.new(1, -8, 1, -8)
resultText.Position = UDim2.new(0, 4, 0, 4)
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Theme.Text
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.RichText = true
resultText.Font = Enum.Font.Code
resultText.TextSize = 11
resultText.Text = "Waiting for data..."

---------------------------------------------------------
-- SHOW/HIDE RESULT LIST BUTTON
---------------------------------------------------------

local toggleResultBtn = Instance.new("TextButton")
toggleResultBtn.Parent = mainFrame
toggleResultBtn.Position = UDim2.new(0, 10, 1, -30)
toggleResultBtn.Size = UDim2.new(1, -20, 0, 20)
toggleResultBtn.BackgroundColor3 = Theme.Secondary
toggleResultBtn.BackgroundTransparency = 0.5
toggleResultBtn.Text = "📋 Show Detail Logs"
toggleResultBtn.Font = Enum.Font.Gotham
toggleResultBtn.TextSize = 10
toggleResultBtn.TextColor3 = Theme.TextDim

local toggleResultCorner = Instance.new("UICorner")
toggleResultCorner.CornerRadius = UDim.new(0, 4)
toggleResultCorner.Parent = toggleResultBtn

toggleResultBtn.MouseButton1Click:Connect(function()
    scrollList.Visible = not scrollList.Visible
    if scrollList.Visible then
        toggleResultBtn.Text = "📋 Hide Detail Logs"
        -- Expand GUI
        mainFrame.Size = UDim2.new(0, 320, 0, 520)
        toggleResultBtn.Position = UDim2.new(0, 10, 0, 320)
        scrollList.Position = UDim2.new(0, 10, 0, 345)
        scrollList.Size = UDim2.new(1, -20, 1, -355)
    else
        toggleResultBtn.Text = "📋 Show Detail Logs"
        mainFrame.Size = UDim2.new(0, 320, 0, 420)
        toggleResultBtn.Position = UDim2.new(0, 10, 1, -30)
    end
end)

---------------------------------------------------------
-- TOGGLE GUI ANIMATION
---------------------------------------------------------

local isGuiVisible = false

local function toggleGui()
    isGuiVisible = not isGuiVisible
    
    if isGuiVisible then
        mainFrame.Visible = true
        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(mainFrame, tweenInfo, {
            Position = UDim2.new(0, 70, 0.5, 0)
        })
        tween:Play()
        toggleButton.Text = "✖"
    else
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(mainFrame, tweenInfo, {
            Position = UDim2.new(0, -400, 0.5, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
        toggleButton.Text = "🥚"
    end
end

toggleButton.MouseButton1Click:Connect(toggleGui)

---------------------------------------------------------
-- UTILS (SAME LOGIC)
---------------------------------------------------------

local function formatTime(s)
    s = math.floor(s)
    if s <= 0 then return "00:00:00" end
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    return string.format("%02d:%02d:%02d", h, m, sec)
end

local function cleanText(str)
    local clean = string.gsub(str, "<.->", "")
    clean = string.gsub(clean, "^%s*(.-)%s*$", "%1")
    return clean
end

local function parseEggLine(text)
    text = cleanText(text)
    text = string.gsub(text, "\n", " ")
    local words = {}
    for w in string.gmatch(text, "%S+") do table.insert(words, w) end
    local eggIndex = nil
    for i, w in ipairs(words) do
        if w:lower() == "egg" then
            eggIndex = i
            break
        end
    end
    if not eggIndex then return nil, nil, nil end
    local eggWords = {}
    for i = 1, eggIndex do table.insert(eggWords, words[i]) end
    local eggName = table.concat(eggWords, " ")
    local petWords = {}
    for i = eggIndex + 1, #words do
        if tonumber(words[i]) then break end
        table.insert(petWords, words[i])
    end
    local petName = table.concat(petWords, " ")
    local kg = nil
    for i = #words, 1, -1 do
        if tonumber(words[i]) then
            kg = tonumber(words[i])
            break
        end
    end
    return eggName, petName, kg
end

local function getTier(kg)
    if not kg then return "Unknown", "#FFFFFF" end
    if kg >= 10 then return "Colossal", "#FF8800"
    elseif kg >= 9 then return "Godly", "#C02030"
    elseif kg >= 8 then return "Titanic", "#7A1B9A"
    elseif kg >= 7 then return "Semi Titanic", "#4E4CBF"
    elseif kg >= 5 then return "Huge", "#2457D5"
    elseif kg >= 3 then return "Semi Huge", "#C69C3A"
    else return "Normal", "#CCCCCC" end
end

local function buildResultList(normalEggs, bigEggs)
    local result = ""
    for eggName, pets in pairs(normalEggs) do
        for petName, info in pairs(pets) do
            local tier, color = getTier(info.maxKG)
            result = result .. string.format("• <font color='%s'>[%s]</font> %s -> %s (%d)\n", color, tier, eggName, petName, info.count)
        end
    end
    for _, e in ipairs(bigEggs) do
        local tier, color = getTier(e.kg)
        result = result .. string.format("• <b><font color='%s'>[%s]</font></b> %s -> %s (%.1f KG)\n", color, tier, e.eggName, e.petName, e.kg)
    end
    return (result == "") and "Belum ada egg dengan KG." or result
end

---------------------------------------------------------
-- COUNT EGGS LOGIC
---------------------------------------------------------

local lastDebugInfo = ""

local function countEggsInFarm()
    local eggCount = 0
    local eggWithTimer = 0
    local debugTexts = {}
    local searchRoot = workspace:FindFirstChild("Farm") or workspace
    
    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible == true then
            local raw = obj.Text
            local cleanedText = cleanText(raw)
            if string.find(raw, "Egg") and not string.find(raw, "KG") then
                eggCount = eggCount + 1
                eggWithTimer = eggWithTimer + 1
                if DEBUG_MODE and #debugTexts < 3 then
                    table.insert(debugTexts, cleanedText:sub(1, 20))
                end
            end
        end
    end
    
    if DEBUG_MODE then
        lastDebugInfo = string.format("LuckyBack:%d (Timer only)", eggCount)
        if #debugTexts > 0 then
            lastDebugInfo = lastDebugInfo .. " | Ex: " .. table.concat(debugTexts, ", ")
        end
    end
    
    return eggCount
end

---------------------------------------------------------
-- WEBHOOK LOGIC (UPDATED WITH VAR)
---------------------------------------------------------

local function sendWebhook(normalEggs, bigEggs, luckyBackCount)
    -- CHECK WEBHOOK VARIABLE
    if not currentWebhookUrl or currentWebhookUrl == "" then
        lblStatus.Text = "Error: Webhook URL belum diisi!"
        lblStatus.TextColor3 = Theme.Red
        warn("Webhook URL kosong! Isi di GUI.")
        return
    end

    lblStatus.Text = "Status: Mengirim Webhook..."
    lblStatus.TextColor3 = Theme.Accent
    
    local runtimeStr = formatTime(tick() - sessionStartTime)
    local messageText = ""
    local hasNewBigEgg = false

    for _, big in ipairs(bigEggs) do
        local key = makeBigEggKey(big.eggName, big.petName, big.kg)
        if not notifiedBigEggs[key] then
            hasNewBigEgg = true
            notifiedBigEggs[key] = true
        end
    end

    for eggName, pets in pairs(normalEggs) do
        for petName, info in pairs(pets) do
            local tier, _ = getTier(info.maxKG)
            messageText = messageText .. string.format("[%s] %s -> %s (%d)\n", tier, eggName, petName, info.count)
        end
    end

    for _, big in ipairs(bigEggs) do
        local tier, _ = getTier(big.kg)
        messageText = messageText .. string.format("[%s] %s -> %s (%.1f KG)\n", tier, big.eggName, big.petName, big.kg)
    end

    if messageText == "" then messageText = "Tidak ada egg ditemukan." end

    local color = hasNewBigEgg and 16711680 or 65280
    local embedData = {
        {
            ["title"] = hasNewBigEgg and "‼️ BIG EGG DETECTED ‼️" or "🥚 Egg Hatched",
            ["description"] = "➤ Detail Batch\n\n" .. messageText,
            ["color"] = color,
            ["fields"] = {
                {["name"] = "⏱ Runtime", ["value"] = runtimeStr, ["inline"] = true},
                {["name"] = "⚡ Last Batch", ["value"] = lastBatchDuration, ["inline"] = true},
                {["name"] = "🥚 Total Hatched", ["value"] = tostring(totalHatched), ["inline"] = true},
                {["name"] = "🍀 Lucky Egg Back", ["value"] = tostring(luckyBackCount), ["inline"] = true}
            },
            ["footer"] = {["text"] = "Egg Tracker V0.5 Remastered"},
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }

    local payload = {
        content = hasNewBigEgg and "@here" or nil,
        embeds = embedData
    }

    local success, jsonBody = pcall(function()
        return HttpService:JSONEncode(payload)
    end)

    if not success then
        lblStatus.Text = "Error: Gagal encode JSON"
        return
    end

    local response = performHttpRequest({
        Url = currentWebhookUrl, -- PAKE VARIABLE BARU
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = jsonBody
    })

    if response then
        lblStatus.Text = "Status: Webhook Terkirim!"
    else
        lblStatus.Text = "Status: Gagal kirim (Nil Request)"
    end
end

---------------------------------------------------------
-- SCANNER LOGIC (SAMA SEPERTI SEBELUMNYA)
---------------------------------------------------------

local function scanGarden()
    if not isRunning then return end

    lblRuntime.Text = "Runtime: " .. formatTime(tick() - sessionStartTime)
    local target = tonumber(targetBox.Text) or DEFAULT_TARGET
    local bigThreshold = tonumber(bigEggBox.Text) or DEFAULT_BIG_EGG_THRESHOLD

    local normalEggs = {}
    local bigEggs = {}
    local totalReady = 0

    local searchRoot = workspace:FindFirstChild("Farm") or workspace
    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible == true then
            local raw = obj.Text
            if string.find(raw, "KG") then
                local eggName, petName, kg = parseEggLine(raw)
                if eggName and petName and kg then
                    totalReady += 1
                    if kg < bigThreshold then
                        normalEggs[eggName] = normalEggs[eggName] or {}
                        normalEggs[eggName][petName] = normalEggs[eggName][petName] or {count = 0, maxKG = 0}
                        normalEggs[eggName][petName].count += 1
                        if kg > normalEggs[eggName][petName].maxKG then
                            normalEggs[eggName][petName].maxKG = kg
                        end
                    else
                        table.insert(bigEggs, {eggName = eggName, petName = petName, kg = kg})
                    end
                end
            end
        end
    end

    local listStr = buildResultList(normalEggs, bigEggs)
    resultText.Text = listStr
    local lineCount = select(2, listStr:gsub("\n", "\n"))
    scrollList.CanvasSize = UDim2.new(0, 0, 0, math.max(lineCount * 18 + 12, scrollList.AbsoluteWindowSize.Y))

    if DEBUG_MODE then
        local countdownStatus = isWaitingForCount and "YES" or "NO"
        local webhookStatus = hasSentWebhook and "YES" or "NO"
        lblDebug.Text = string.format("Debug: Ready(KG)=%d | Target=%d | Countdown=%s | Sent=%s", 
            totalReady, target, countdownStatus, webhookStatus)
    end

    -- LOGIC BARU: Lucky Egg Back Detection (25 detik countdown)
    if isWaitingForCount and not hasSentWebhook then
        local elapsed = tick() - countdownStartTime
        local remaining = COUNTDOWN_SECONDS - elapsed
        
        if remaining > 0 then
            lblStatus.Text = string.format("Status: Countdown %.0fs... (Initial: %d eggs)", remaining, initialEggCount)
            lblStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
            if DEBUG_MODE then
                lblDebug.Text = string.format("Debug: COUNTDOWN | Ready=%d | Wait=%.0fs | LOCKED", totalReady, remaining)
            end
        else
            local currentEggCount = countEggsInFarm()
            luckyEggBackCount = currentEggCount
            if luckyEggBackCount < 0 then luckyEggBackCount = 0 end
            
            lblLuckyBack.Text = "Lucky Egg Back: " .. luckyEggBackCount
            lblStatus.Text = string.format("Status: Sending webhook...")
            
            if DEBUG_MODE then
                lblDebug.Text = string.format("Debug: COUNTDOWN END | %s", lastDebugInfo)
            end
            
            local dur = tick() - batchStartTime
            if dur < 60 then lastBatchDuration = math.floor(dur) .. "s"
            else lastBatchDuration = math.floor(dur / 60) .. "m " .. math.floor(dur % 60) .. "s" end
            
            totalHatched += initialEggCount
            lblLastBatch.Text = "Last Batch Time: " .. lastBatchDuration
            lblHatched.Text = "Total Hatched: " .. totalHatched
            
            sendWebhook(snapshotNormalEggs, snapshotBigEggs, luckyEggBackCount)
            
            hasSentWebhook = true
            isWaitingForCount = false
            countdownStartTime = 0
            
            if DEBUG_MODE then
                lblDebug.Text = "Debug: WEBHOOK SENT | Ready for reset"
            end
            task.wait(0.5)
        end
    elseif totalReady >= target then
        if not isWaitingForCount and not hasSentWebhook then
            snapshotNormalEggs = {}
            snapshotBigEggs = {}
            snapshotTotalReady = totalReady
            
            for eggName, pets in pairs(normalEggs) do
                snapshotNormalEggs[eggName] = {}
                for petName, info in pairs(pets) do
                    snapshotNormalEggs[eggName][petName] = {
                        count = info.count,
                        maxKG = info.maxKG
                    }
                end
            end
            
            for _, big in ipairs(bigEggs) do
                table.insert(snapshotBigEggs, {
                    eggName = big.eggName,
                    petName = big.petName,
                    kg = big.kg
                })
            end
            
            isWaitingForCount = true
            countdownStartTime = tick()
            initialEggCount = totalReady
            luckyEggBackCount = 0
            lblStatus.Text = "Status: Countdown 25s dimulai..."
            if DEBUG_MODE then
                lblDebug.Text = string.format("Debug: START COUNTDOWN | Initial=%d eggs | Snapshot=%d", initialEggCount, snapshotTotalReady)
            end
        end
    else
        if hasSentWebhook and totalReady < target then
            if DEBUG_MODE then
                lblDebug.Text = string.format("Debug: RESET | Ready=%d < Target=%d", totalReady, target)
            end
            hasSentWebhook = false
            isWaitingForCount = false
            countdownStartTime = 0
            luckyEggBackCount = 0
            initialEggCount = 0
            snapshotNormalEggs = {}
            snapshotBigEggs = {}
            snapshotTotalReady = 0
            batchStartTime = tick()
            lblStatus.Text = "Status: Reset. New Batch."
            lblStatus.TextColor3 = Theme.Accent
        elseif not hasSentWebhook and not isWaitingForCount then
            lblStatus.Text = "Status: Mengisi (" .. totalReady .. "/" .. target .. ")"
            lblStatus.TextColor3 = Theme.TextDim
        end
    end
end

---------------------------------------------------------
-- BUTTON LOGIC
---------------------------------------------------------

toggleBtn.MouseButton1Click:Connect(function()
    if currentWebhookUrl == "" then
        lblStatus.Text = "⚠ ISI WEBHOOK DULU!"
        lblStatus.TextColor3 = Theme.Red
        return
    end

    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "PAUSE / STOP"
        toggleBtn.BackgroundColor3 = Theme.Red
        if sessionStartTime == 0 then
            sessionStartTime = tick()
            batchStartTime = tick()
            lblStatus.Text = "Status: Started."
        end
    else
        toggleBtn.Text = "RESUME"
        toggleBtn.BackgroundColor3 = Theme.Accent
        lblStatus.Text = "Status: Paused."
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    isRunning = false
    if screenGui then screenGui:Destroy() end
end)

debugToggleBtn.MouseButton1Click:Connect(function()
    DEBUG_MODE = not DEBUG_MODE
    if DEBUG_MODE then
        debugToggleBtn.BackgroundColor3 = Theme.Accent
        lblDebug.Visible = true
    else
        debugToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        lblDebug.Visible = false
    end
end)

---------------------------------------------------------
-- MAIN LOOP
---------------------------------------------------------

task.spawn(function()
    while true do
        local ok, err = pcall(scanGarden)
        if not ok then lblStatus.Text = "ERR: " .. tostring(err) end
        task.wait(1)
    end
end)
