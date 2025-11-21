--[[
    GARDEN TRACKER FINAL VERSION (FIXED FOR DELTA)
    Features:
    - Fix Webhook Body (JSON Encode)
    - Fix Delta Request Detection
    - GUI resizable & Batch tracking maintained
]]--

---------------------------------------------------------
-- SERVICES
---------------------------------------------------------

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- [PERBAIKAN 1]: Deteksi request yang lebih baik untuk Delta/Mobile Executor
local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request or function()
    warn("Executor kamu TIDAK mendukung HTTP request.")
    return nil
end

---------------------------------------------------------
-- CONFIG
---------------------------------------------------------

local WEBHOOK_URL = "https://discord.com/api/webhooks/1417836981353713684/yPh7jTLDmX7n_rj2-KOanHl6iPGDlvUpHJeCZG90pFOG0NQrwQ6c_e94_tOFRRJ6_sYJ"
local DEFAULT_TARGET = 8
local DEFAULT_BIG_EGG_THRESHOLD = 3

---------------------------------------------------------
-- STATE
---------------------------------------------------------

local isRunning = false
local sessionStartTime = 0
local batchStartTime = 0
local totalHatched = 0
local lastBatchDuration = "0s"
local hasSentWebhook = false

-- cache big egg yang sudah pernah dikirim agar tidak spam
local notifiedBigEggs = {}

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
-- MAIN GUI CREATION
---------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GardenUltimate"
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 280, 0, 380)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local originalSize = mainFrame.Size

---------------------------------------------------------
-- TITLE BAR
---------------------------------------------------------

local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
title.Text = "Garden Tracker V0.3 (Fix)"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

---------------------------------------------------------
-- CLOSE & MINIMIZE
---------------------------------------------------------

local isMinimized = false

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

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = mainFrame
minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
minimizeBtn.Position = UDim2.new(1, -50, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(1,0)
miniCorner.Parent = minimizeBtn

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

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleBtn

---------------------------------------------------------
-- STATS LABELS
---------------------------------------------------------

local statsContainer = Instance.new("Frame")
statsContainer.Parent = mainFrame
statsContainer.Position = UDim2.new(0, 12, 0, 142)
statsContainer.Size = UDim2.new(1, -24, 0, 70)
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
local lblStatus = makeLabel("Status: IDLE", 48)
lblStatus.TextColor3 = Color3.fromRGB(255, 230, 120)

---------------------------------------------------------
-- RESULT LIST (SCROLLING)
---------------------------------------------------------

local scrollList = Instance.new("ScrollingFrame")
scrollList.Parent = mainFrame
scrollList.Position = UDim2.new(0, 12, 0, 220)
scrollList.Size = UDim2.new(1, -24, 1, -232)
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
-- RESIZE HANDLE (BOTTOM-RIGHT)
---------------------------------------------------------

local resizeHandle = Instance.new("Frame")
resizeHandle.Parent = mainFrame
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -4, 1, -4)
resizeHandle.Size = UDim2.new(0, 14, 0, 14)
resizeHandle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
resizeHandle.BorderSizePixel = 0

local resizeCorner = Instance.new("UICorner")
resizeCorner.CornerRadius = UDim.new(0, 4)
resizeCorner.Parent = resizeHandle

local isResizing = false
local lastInputPos

resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        isResizing = true
        lastInputPos = input.Position
    end
end)

resizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        isResizing = false
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        isResizing = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not isResizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local currentPos = input.Position
    local delta = currentPos - lastInputPos
    lastInputPos = currentPos

    local newW = math.clamp(mainFrame.Size.X.Offset + delta.X, 260, 520)
    local newH = math.clamp(mainFrame.Size.Y.Offset + delta.Y, 260, 620)

    mainFrame.Size = UDim2.new(0, newW, 0, newH)
end)
---------------------------------------------------------
-- UTILITY: FORMAT TIME (detik → HH:MM:SS)
---------------------------------------------------------

local function formatTime(s)
    s = math.floor(s)
    if s <= 0 then return "00:00:00" end
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    return string.format("%02d:%02d:%02d", h, m, sec)
end

---------------------------------------------------------
-- UTILITY: HAPUS HTML TAG DARI LABEL (ESP TEXT)
---------------------------------------------------------

local function cleanText(str)
    local clean = string.gsub(str, "<.->", "")
    clean = string.gsub(clean, "^%s*(.-)%s*$", "%1")
    return clean
end

---------------------------------------------------------
-- PARSER: MENGAMBIL EGG NAME, PET NAME, DAN KG
---------------------------------------------------------

local function parseEggLine(text)
    text = cleanText(text)
    text = string.gsub(text, "\n", " ")

    local words = {}
    for w in string.gmatch(text, "%S+") do
        table.insert(words, w)
    end

    local eggIndex = nil
    for i, w in ipairs(words) do
        if w:lower() == "egg" then
            eggIndex = i
            break
        end
    end

    if not eggIndex then return nil, nil, nil end

    local eggWords = {}
    for i = 1, eggIndex do
        table.insert(eggWords, words[i])
    end
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

---------------------------------------------------------
-- TIER LOGIC
---------------------------------------------------------

local function getTier(kg)
    if not kg then return "Unknown", "#FFFFFF" end

    if kg >= 10 then
        return "Colossal", "#FF8800"
    elseif kg >= 9 then
        return "Godly", "#C02030"
    elseif kg >= 8 then
        return "Titanic", "#7A1B9A"
    elseif kg >= 7 then
        return "Semi Titanic", "#4E4CBF"
    elseif kg >= 5 then
        return "Huge", "#2457D5"
    elseif kg >= 3 then
        return "Semi Huge", "#C69C3A"
    else
        return "Normal", "#CCCCCC"
    end
end

---------------------------------------------------------
-- BUILDING RICH TEXT LIST OF RESULTS FOR UI
---------------------------------------------------------

local function buildResultList(normalEggs, bigEggs)
    local result = ""

    for eggName, pets in pairs(normalEggs) do
        for petName, info in pairs(pets) do
            local tier, color = getTier(info.maxKG)
            result = result .. string.format(
                "• <font color='%s'>[%s]</font> %s -> %s (%d)\n",
                color,
                tier,
                eggName,
                petName,
                info.count
            )
        end
    end

    for _, e in ipairs(bigEggs) do
        local tier, color = getTier(e.kg)
        result = result .. string.format(
            "• <b><font color='%s'>[%s]</font></b> %s -> %s (%.1f KG)\n",
            color,
            tier,
            e.eggName,
            e.petName,
            e.kg
        )
    end

    if result == "" then
        return "Belum ada egg dengan KG."
    end

    return result
end
---------------------------------------------------------
-- SCANNER
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
                        normalEggs[eggName][petName] =
                            normalEggs[eggName][petName] or {count = 0, maxKG = 0}

                        normalEggs[eggName][petName].count = 
						normalEggs[eggName][petName].count + 1
                        if kg > normalEggs[eggName][petName].maxKG then
                            normalEggs[eggName][petName].maxKG = kg
                        end
                    else
                        table.insert(bigEggs, {
                            eggName = eggName,
                            petName = petName,
                            kg = kg
                        })
                    end
                end
            end
        end
    end

    local listStr = buildResultList(normalEggs, bigEggs)
    resultText.Text = listStr

    local lineCount = select(2, listStr:gsub("\n", "\n"))
    scrollList.CanvasSize = UDim2.new(
        0, 0,
        0, math.max(lineCount * 18 + 12, scrollList.AbsoluteWindowSize.Y)
    )

    if totalReady >= target then
        if not hasSentWebhook then

            local dur = tick() - batchStartTime
            if dur < 60 then
                lastBatchDuration = math.floor(dur) .. "s"
            else
                lastBatchDuration =
                    math.floor(dur / 60) .. "m " .. math.floor(dur % 60) .. "s"
            end

            totalHatched = totalHatched + totalReady

            lblLastBatch.Text = "Last Batch Time: " .. lastBatchDuration
            lblHatched.Text = "Total Hatched: " .. totalHatched

            sendWebhook(normalEggs, bigEggs)

            hasSentWebhook = true
        end

    else
        if hasSentWebhook and totalReady < (target / 2) then
            hasSentWebhook = false
            batchStartTime = tick()
            lblStatus.Text = "Status: Reset. New Batch."
        elseif not hasSentWebhook then
            lblStatus.Text = "Status: Mengisi (" .. totalReady .. "/" .. target .. ")"
        end
    end
end
---------------------------------------------------------
-- WEBHOOK SYSTEM (ANTI-SPAM BIG EGG)
---------------------------------------------------------

local function sendWebhook(normalEggs, bigEggs)
    if not WEBHOOK_URL or WEBHOOK_URL == "" then
        warn("Webhook URL tidak diisi.")
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
            messageText = messageText ..
                string.format("[%s] %s -> %s (%d)\n",
                    tier,
                    eggName,
                    petName,
                    info.count
                )
        end
    end

    for _, big in ipairs(bigEggs) do
        local tier, _ = getTier(big.kg)
        messageText = messageText ..
            string.format("[%s] %s -> %s (%.1f KG)\n",
                tier,
                big.eggName,
                big.petName,
                big.kg
            )
    end

    if messageText == "" then
        messageText = "Tidak ada egg ditemukan."
    end

    local color = hasNewBigEgg and 16711680 or 65280

    local embedData = {
        {
            ["title"] = hasNewBigEgg
                and "‼️ BIG EGG DETECTED ‼️"
                or "Egg Batch Siap Dibuka",
            ["description"] = "➤ Detail Batch\n\n" .. messageText,
            ["color"] = color,

            ["fields"] = {
                {
                    ["name"] = "⏱ Runtime",
                    ["value"] = runtimeStr,
                    ["inline"] = true
                },
                {
                    ["name"] = "⚡ Last Batch",
                    ["value"] = lastBatchDuration,
                    ["inline"] = true
                },
                {
                    ["name"] = "🥚 Total Hatched",
                    ["value"] = tostring(totalHatched),
                    ["inline"] = true
                }
            },

            ["footer"] = {["text"] = "Garden Tracker"},
            ["timestamp"] = DateTime.now():ToIsoDate()
        }
    }

    local payload = {
        content = hasNewBigEgg and "@here" or nil,
        embeds = embedData
    }

    -- [PERBAIKAN 2]: Menambahkan JSONEncode pada Body
    if request then
	    request({
	        Url = WEBHOOK_URL,
	        Method = "POST",
	        Headers = {["Content-Type"] = "application/json"},
	        Body = HttpService:JSONEncode(payload) -- WAJIB DI ENCODE JSON
	    })
	else
	    warn("Tidak bisa mengirim webhook: request() tidak ada.")
	end
    lblStatus.Text = "Status: Webhook Terkirim!"
end
---------------------------------------------------------
-- BUTTON LOGIC: START / STOP
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

---------------------------------------------------------
-- CLOSE BUTTON
---------------------------------------------------------

closeBtn.MouseButton1Click:Connect(function()
    isRunning = false
    if screenGui then
        screenGui:Destroy()
    end
end)

---------------------------------------------------------
-- MINIMIZE BUTTON
---------------------------------------------------------

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized

    if isMinimized then
        minimizeBtn.Text = "+"
        originalSize = mainFrame.Size
        mainFrame.Size = UDim2.new(0, 280, 0, 32)

        for _, child in ipairs(mainFrame:GetChildren()) do
            if child ~= title and child ~= closeBtn and child ~= minimizeBtn then
                if child:IsA("GuiObject") then
                    child.Visible = false
                end
            end
        end

    else
        minimizeBtn.Text = "-"
        mainFrame.Size = originalSize

        for _, child in ipairs(mainFrame:GetChildren()) do
            if child ~= title and child ~= closeBtn and child ~= minimizeBtn then
                if child:IsA("GuiObject") then
                    child.Visible = true
                end
            end
        end
    end
end)

---------------------------------------------------------
-- MAIN BACKGROUND LOOP (SCANNER)
---------------------------------------------------------

task.spawn(function()
    while true do
        local ok, err = pcall(function()
            scanGarden()
        end)

        if not ok then
            lblStatus.Text = "ERROR: " .. tostring(err)
        end

        task.wait(1)
    end
end)
