--[[
    GARDEN TRACKER V0.4 (TOGGLE UI + LUCKY EGG BACK)
    New Features:
    - Toggle button di kiri tengah untuk buka/tutup GUI
    - Lucky Egg Back detection dengan countdown 25 detik
    - Menghitung egg yang MASIH ADA di farm setelah 25 detik
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

---------------------------------------------------------
-- CONFIG
---------------------------------------------------------

local WEBHOOK_URL = "https://discord.com/api/webhooks/1417836981353713684/yPh7jTLDmX7n_rj2-KOanHl6iPGDlvUpHJeCZG90pFOG0NQrwQ6c_e94_tOFRRJ6_sYJ"
local DEFAULT_TARGET = 13
local DEFAULT_BIG_EGG_THRESHOLD = 3

---------------------------------------------------------
-- HELPER: SAFE HTTP REQUEST
---------------------------------------------------------

local function performHttpRequest(options)
    local reqFunc = nil

    if type(http_request) == "function" then
        reqFunc = http_request
    elseif type(request) == "function" then
        reqFunc = request
    elseif type(syn) == "table" and type(syn.request) == "function" then
        reqFunc = syn.request
    elseif type(fluxus) == "table" and type(fluxus.request) == "function" then
        reqFunc = fluxus.request
    elseif type(getgenv) == "function" then
        local env = getgenv()
        if env.request then reqFunc = env.request
        elseif env.http_request then reqFunc = env.http_request end
    end

    if reqFunc then
        return reqFunc(options)
    else
        warn("⚠ FATAL: Executor kamu tidak memiliki fungsi request/http_request!")
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
local COUNTDOWN_SECONDS = 20

local function makeBigEggKey(eggName, petName, kg)
    return string.format("%s|%s|%.1f", eggName, petName, kg)
end

---------------------------------------------------------
-- CLEANUP GUI EXISTING
---------------------------------------------------------

if player.PlayerGui:FindFirstChild("GardenUltimate") then
    player.PlayerGui.GardenUltimate:Destroy()
end

---------------------------------------------------------
-- TOGGLE BUTTON (KIRI TENGAH)
---------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GardenUltimate"
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Parent = screenGui
toggleButton.AnchorPoint = Vector2.new(0, 0.5)
toggleButton.Position = UDim2.new(0, 10, 0.5, 0)
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
toggleButton.BorderSizePixel = 0
toggleButton.Text = "🌱"
toggleButton.TextSize = 24
toggleButton.Font = Enum.Font.GothamBold

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 25)
toggleCorner.Parent = toggleButton

-- Shadow effect
local toggleShadow = Instance.new("ImageLabel")
toggleShadow.Name = "Shadow"
toggleShadow.Parent = toggleButton
toggleShadow.BackgroundTransparency = 1
toggleShadow.Position = UDim2.new(0, -10, 0, -10)
toggleShadow.Size = UDim2.new(1, 20, 1, 20)
toggleShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
toggleShadow.ImageTransparency = 0.7
toggleShadow.ZIndex = 0

---------------------------------------------------------
-- MAIN GUI CREATION
---------------------------------------------------------

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.Position = UDim2.new(0, -300, 0.5, 0) -- Hidden initially
mainFrame.Size = UDim2.new(0, 280, 0, 420)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Visible = false

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

---------------------------------------------------------
-- TITLE BAR
---------------------------------------------------------

local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
title.Text = "Garden Tracker V0.4"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

---------------------------------------------------------
-- CLOSE BUTTON
---------------------------------------------------------

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = mainFrame
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -26, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1,0)
closeCorner.Parent = closeBtn

---------------------------------------------------------
-- TARGET INPUT
---------------------------------------------------------

local labelTarget = Instance.new("TextLabel")
labelTarget.Parent = mainFrame
labelTarget.Position = UDim2.new(0, 12, 0, 42)
labelTarget.Size = UDim2.new(0.5, 0, 0, 22)
labelTarget.BackgroundTransparency = 1
labelTarget.Text = "Target Batch:"
labelTarget.TextColor3 = Color3.fromRGB(220,220,220)
labelTarget.TextXAlignment = Enum.TextXAlignment.Left
labelTarget.Font = Enum.Font.Gotham
labelTarget.TextSize = 12

local targetBox = Instance.new("TextBox")
targetBox.Parent = mainFrame
targetBox.Position = UDim2.new(0.55, -4, 0, 42)
targetBox.Size = UDim2.new(0.4, -8, 0, 22)
targetBox.Text = tostring(DEFAULT_TARGET)
targetBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
targetBox.TextColor3 = Color3.new(1,1,1)
targetBox.Font = Enum.Font.GothamBold
targetBox.TextSize = 12
targetBox.ClearTextOnFocus = false

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 6)
targetCorner.Parent = targetBox

---------------------------------------------------------
-- BIG EGG THRESHOLD INPUT
---------------------------------------------------------

local labelBig = Instance.new("TextLabel")
labelBig.Parent = mainFrame
labelBig.Position = UDim2.new(0, 12, 0, 70)
labelBig.Size = UDim2.new(0.5, 0, 0, 22)
labelBig.BackgroundTransparency = 1
labelBig.Text = "Big Egg ≥ KG:"
labelBig.TextColor3 = Color3.fromRGB(220, 220, 220)
labelBig.TextXAlignment = Enum.TextXAlignment.Left
labelBig.Font = Enum.Font.Gotham
labelBig.TextSize = 12

local bigEggBox = Instance.new("TextBox")
bigEggBox.Parent = mainFrame
bigEggBox.Position = UDim2.new(0.55, -4, 0, 70)
bigEggBox.Size = UDim2.new(0.4, -8, 0, 22)
bigEggBox.Text = tostring(DEFAULT_BIG_EGG_THRESHOLD)
bigEggBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
bigEggBox.TextColor3 = Color3.new(1,1,1)
bigEggBox.Font = Enum.Font.GothamBold
bigEggBox.TextSize = 12
bigEggBox.ClearTextOnFocus = false

local bigCorner = Instance.new("UICorner")
bigCorner.CornerRadius = UDim.new(0, 6)
bigCorner.Parent = bigEggBox

---------------------------------------------------------
-- START / STOP BUTTON
---------------------------------------------------------

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = mainFrame
toggleBtn.Position = UDim2.new(0, 12, 0, 102)
toggleBtn.Size = UDim2.new(1, -24, 0, 32)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
toggleBtn.Text = "START / RESUME"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.new(1, 1, 1)

local toggleBtnCorner = Instance.new("UICorner")
toggleBtnCorner.CornerRadius = UDim.new(0, 6)
toggleBtnCorner.Parent = toggleBtn

---------------------------------------------------------
-- STATS LABELS
---------------------------------------------------------

local statsContainer = Instance.new("Frame")
statsContainer.Parent = mainFrame
statsContainer.Position = UDim2.new(0, 12, 0, 142)
statsContainer.Size = UDim2.new(1, -24, 0, 86)
statsContainer.BackgroundTransparency = 1

local function makeLabel(txt, y)
    local l = Instance.new("TextLabel")
    l.Parent = statsContainer
    l.Position = UDim2.new(0, 0, 0, y)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Code
    l.TextSize = 12
    l.Text = txt
    return l
end

local lblRuntime = makeLabel("Runtime: 00:00:00", 0)
local lblHatched = makeLabel("Total Hatched: 0", 16)
local lblLastBatch = makeLabel("Last Batch Time: -", 32)
local lblLuckyBack = makeLabel("Lucky Egg Back: 0", 48)
lblLuckyBack.TextColor3 = Color3.fromRGB(255, 200, 80)
local lblStatus = makeLabel("Status: IDLE", 64)
lblStatus.TextColor3 = Color3.fromRGB(255, 230, 120)

---------------------------------------------------------
-- RESULT LIST (SCROLLING)
---------------------------------------------------------

local scrollList = Instance.new("ScrollingFrame")
scrollList.Parent = mainFrame
scrollList.Position = UDim2.new(0, 12, 0, 236)
scrollList.Size = UDim2.new(1, -24, 1, -248)
scrollList.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollList.ScrollBarThickness = 4

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollList

local resultText = Instance.new("TextLabel")
resultText.Parent = scrollList
resultText.Size = UDim2.new(1, -8, 1, -8)
resultText.Position = UDim2.new(0, 4, 0, 4)
resultText.BackgroundTransparency = 1
resultText.TextColor3 = Color3.new(1, 1, 1)
resultText.TextXAlignment = Enum.TextXAlignment.Left
resultText.TextYAlignment = Enum.TextYAlignment.Top
resultText.RichText = true
resultText.Font = Enum.Font.Code
resultText.TextSize = 12
resultText.Text = "Tekan START..."

---------------------------------------------------------
-- TOGGLE GUI ANIMATION
---------------------------------------------------------

local isGuiVisible = false

local function toggleGui()
    isGuiVisible = not isGuiVisible
    
    if isGuiVisible then
        mainFrame.Visible = true
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(mainFrame, tweenInfo, {
            Position = UDim2.new(0, 70, 0.5, 0)
        })
        tween:Play()
        
        toggleButton.Text = "❌"
    else
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(mainFrame, tweenInfo, {
            Position = UDim2.new(0, -300, 0.5, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
        
        toggleButton.Text = "🌱"
    end
end

toggleButton.MouseButton1Click:Connect(toggleGui)

---------------------------------------------------------
-- UTILS
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
-- COUNT EGGS IN FARM
---------------------------------------------------------

local function countEggsInFarm()
    local eggCount = 0
    local searchRoot = workspace:FindFirstChild("Farm") or workspace
    
    for _, obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible == true then
            local raw = obj.Text
            -- Hitung semua egg (baik yang KG maupun timer)
            if string.find(raw, "Egg") or string.find(raw, "KG") or string.match(raw, "%d+:%d+") then
                eggCount = eggCount + 1
            end
        end
    end
    
    return eggCount
end

---------------------------------------------------------
-- WEBHOOK LOGIC
---------------------------------------------------------

local function sendWebhook(normalEggs, bigEggs, luckyBackCount)
    if not WEBHOOK_URL or WEBHOOK_URL == "" then
        warn("Webhook URL kosong")
        return
    end

    lblStatus.Text = "Status: Mengirim Webhook..."
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
            ["title"] = hasNewBigEgg and "‼️ BIG EGG DETECTED ‼️" or "Egg Batch Siap Dibuka",
            ["description"] = "➤ Detail Batch\n\n" .. messageText,
            ["color"] = color,
            ["fields"] = {
                {["name"] = "⏱ Runtime", ["value"] = runtimeStr, ["inline"] = true},
                {["name"] = "⚡ Last Batch", ["value"] = lastBatchDuration, ["inline"] = true},
                {["name"] = "🥚 Total Hatched", ["value"] = tostring(totalHatched), ["inline"] = true},
                {["name"] = "🍀 Lucky Egg Back", ["value"] = tostring(luckyBackCount), ["inline"] = true}
            },
            ["footer"] = {["text"] = "kambingnoob"},
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
        Url = WEBHOOK_URL,
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
-- SCANNER LOGIC WITH LUCKY EGG BACK
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

    -- LOGIC BARU: Lucky Egg Back Detection (25 detik countdown)
    if totalReady >= target then
        if not isWaitingForCount and not hasSentWebhook then
            -- Semua egg ready, mulai countdown 25 detik
            isWaitingForCount = true
            countdownStartTime = tick()
            initialEggCount = totalReady
            luckyEggBackCount = 0
            lblStatus.Text = "Status: Countdown 25s dimulai..."
        elseif isWaitingForCount and not hasSentWebhook then
            -- Hitung sisa waktu countdown
            local elapsed = tick() - countdownStartTime
            local remaining = COUNTDOWN_SECONDS - elapsed
            
            if remaining > 0 then
                -- Masih dalam countdown
                lblStatus.Text = string.format("Status: Countdown %.0fs... (Initial: %d eggs)", remaining, initialEggCount)
            else
                -- Countdown selesai, hitung egg yang masih ada
                local currentEggCount = countEggsInFarm()
                luckyEggBackCount = currentEggCount  -- Yang masih ada = Lucky Egg Back
                
                if luckyEggBackCount < 0 then luckyEggBackCount = 0 end
                
                lblLuckyBack.Text = "Lucky Egg Back: " .. luckyEggBackCount
                lblStatus.Text = string.format("Status: Lucky Egg Back = %d eggs", luckyEggBackCount)
                
                -- Kirim webhook
                local dur = tick() - batchStartTime
                if dur < 60 then lastBatchDuration = math.floor(dur) .. "s"
                else lastBatchDuration = math.floor(dur / 60) .. "m " .. math.floor(dur % 60) .. "s" end
                
                totalHatched += initialEggCount  -- Pakai initialEggCount bukan totalReady
                lblLastBatch.Text = "Last Batch Time: " .. lastBatchDuration
                lblHatched.Text = "Total Hatched: " .. totalHatched
                
                sendWebhook(normalEggs, bigEggs, luckyEggBackCount)
                hasSentWebhook = true
                isWaitingForCount = false
                countdownStartTime = 0
            end
        end
    else
        -- Reset jika egg berkurang (sudah di-hatch atau countdown selesai)
        if (hasSentWebhook or isWaitingForCount) and totalReady < target then
            hasSentWebhook = false
            isWaitingForCount = false
            countdownStartTime = 0
            luckyEggBackCount = 0
            initialEggCount = 0
            batchStartTime = tick()
            lblStatus.Text = "Status: Reset. New Batch."
        elseif not hasSentWebhook and not isWaitingForCount then
            lblStatus.Text = "Status: Mengisi (" .. totalReady .. "/" .. target .. ")"
        end
    end
end

---------------------------------------------------------
-- BUTTON LOGIC
---------------------------------------------------------

toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "PAUSE / STOP"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        if sessionStartTime == 0 then
            sessionStartTime = tick()
            batchStartTime = tick()
            lblStatus.Text = "Status: Started."
        end
    else
        toggleBtn.Text = "RESUME"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
        lblStatus.Text = "Status: Paused."
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    isRunning = false
    if screenGui then screenGui:Destroy() end
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
