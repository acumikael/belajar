-- ======================================================
-- TARGETED EGG READER (PATH SPESIFIK)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- 1. HAPUS GUI LAMA
if player.PlayerGui:FindFirstChild("TargetedEggCounter") then
    player.PlayerGui.TargetedEggCounter:Destroy()
end

-- 2. SETUP GUI (Tampilan Rapi)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TargetedEggCounter"
screenGui.Parent = player:WaitForChild("PlayerGui")

local infoBox = Instance.new("Frame")
infoBox.Name = "InfoBox"
infoBox.Parent = screenGui
infoBox.AnchorPoint = Vector2.new(0.5, 0) 
infoBox.Position = UDim2.new(0.5, 0, 0.18, 0) -- Posisi di bawah Pet Counter & Tombol
infoBox.Size = UDim2.new(0, 200, 0, 100)
infoBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
infoBox.BackgroundTransparency = 0.2
infoBox.BorderColor3 = Color3.fromRGB(255, 0, 255) -- Border Ungu Neon
infoBox.BorderSizePixel = 2

local title = Instance.new("TextLabel")
title.Parent = infoBox
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "ISI KEBUN (DETECTED)"
title.TextColor3 = Color3.fromRGB(255, 0, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local statusLabel = Instance.new("TextLabel") -- Untuk Debug status
statusLabel.Parent = infoBox
statusLabel.Position = UDim2.new(0, 0, 1, -15)
statusLabel.Size = UDim2.new(1, 0, 0, 15)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 10
statusLabel.Text = "Status: Memulai..."

local listLabel = Instance.new("TextLabel")
listLabel.Parent = infoBox
listLabel.Position = UDim2.new(0, 10, 0, 30)
listLabel.Size = UDim2.new(1, -20, 1, -40)
listLabel.BackgroundTransparency = 1
listLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
listLabel.Font = Enum.Font.Code
listLabel.TextSize = 13
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.TextYAlignment = Enum.TextYAlignment.Top
listLabel.Text = "Mencari Folder..."
listLabel.RichText = true

-- 3. FUNGSI MEMBERSIHKAN TEKS HTML
local function cleanText(str)
    local clean = string.gsub(str, "<.->", "") -- Hapus tag font/color
    clean = string.match(clean, "^%s*(.-)%s*$") -- Hapus spasi
    return clean
end

-- 4. FUNGSI MENCARI FOLDER TARGET SECARA AMAN
local function getTargetFolder()
    -- Urutan Path: Farm -> Farm -> Important -> Objects_Physical
    local f1 = Workspace:FindFirstChild("Farm")
    if not f1 then return nil, "Farm (1) tidak ketemu" end
    
    local f2 = f1:FindFirstChild("Farm")
    if not f2 then return nil, "Farm (2) tidak ketemu" end
    
    local f3 = f2:FindFirstChild("Important")
    if not f3 then return nil, "Folder 'Important' tidak ketemu" end
    
    -- Coba cari Objects_Physical (Underscore) ATAU Objects-Physical (Strip)
    local f4 = f3:FindFirstChild("Objects_Physical") or f3:FindFirstChild("Objects-Physical")
    if not f4 then return nil, "Objects_Physical tidak ketemu" end
    
    return f4, "Folder OK"
end

-- 5. LOOP UTAMA
task.spawn(function()
    while true do
        local folder, status = getTargetFolder()
        statusLabel.Text = "Status: " .. status
        
        if folder then
            local counts = {}
            local totalDetected = 0
            
            -- Scan semua anak di dalam folder target
            for _, item in ipairs(folder:GetDescendants()) do
                -- Kita cari TextLabel yg ada di dalam BillboardGui
                if item:IsA("TextLabel") and item.Parent:IsA("BillboardGui") then
                    local rawText = item.Text
                    
                    -- Cek apakah ini teks ESP (ada kode warnanya)
                    -- Atau kalau script ESP itu sudah membersihkan teksnya, kita ambil apa adanya
                    if string.find(rawText, "<font") or string.len(rawText) > 2 then
                        local name = cleanText(rawText)
                        
                        -- Filter sampah (angka, titik, dll)
                        if name ~= "" and not tonumber(name) and name ~= "..." then
                            totalDetected = totalDetected + 1
                            counts[name] = (counts[name] or 0) + 1
                        end
                    end
                end
            end
            
            -- Tampilkan Hasil
            if totalDetected > 0 then
                local displayText = ""
                local sortedNames = {}
                for name in pairs(counts) do table.insert(sortedNames, name) end
                table.sort(sortedNames)
                
                for _, name in ipairs(sortedNames) do
                    displayText = displayText .. "• " .. name .. ": <b>" .. counts[name] .. "</b>\n"
                end
                listLabel.Text = displayText
                -- Resize kotak
                infoBox.Size = UDim2.new(0, 200, 0, 50 + (#sortedNames * 15))
            else
                listLabel.Text = "ESP Aktif, tapi belum ada telur terdeteksi."
            end
        else
            listLabel.Text = "Path Error: " .. status
        end
        
        task.wait(1) -- Update setiap detik
    end
end)
