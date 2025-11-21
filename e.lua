-- ======================================================
-- EGG PREDICTION READER (Membaca ESP Orang Lain)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. HAPUS GUI LAMA
if player.PlayerGui:FindFirstChild("EggPredictionGui") then
    player.PlayerGui.EggPredictionGui:Destroy()
end

-- 2. SETUP GUI (Tampilan Kotak di Tengah Atas)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggPredictionGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local infoBox = Instance.new("Frame")
infoBox.Name = "InfoBox"
infoBox.Parent = screenGui
infoBox.AnchorPoint = Vector2.new(0.5, 0) 
infoBox.Position = UDim2.new(0.5, 0, 0.12, 0) -- Posisi di bawah penghitung pet
infoBox.Size = UDim2.new(0, 180, 0, 100) -- Ukuran kotak
infoBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
infoBox.BackgroundTransparency = 0.3
infoBox.BorderColor3 = Color3.fromRGB(0, 255, 100)
infoBox.BorderSizePixel = 2

local title = Instance.new("TextLabel")
title.Parent = infoBox
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "PREDIKSI ISI KEBUN"
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local listLabel = Instance.new("TextLabel")
listLabel.Parent = infoBox
listLabel.Position = UDim2.new(0, 10, 0, 30)
listLabel.Size = UDim2.new(1, -20, 1, -35)
listLabel.BackgroundTransparency = 1
listLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
listLabel.Font = Enum.Font.Code
listLabel.TextSize = 13
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.TextYAlignment = Enum.TextYAlignment.Top
listLabel.Text = "Scanning..."
listLabel.RichText = true -- Agar bisa baca format tebal

-- 3. FUNGSI MEMBERSIHKAN TEKS HTML
-- Mengubah "<font color=...>Cow</font>" menjadi "Cow"
local function cleanText(str)
    -- Hapus semua tag <...>
    local clean = string.gsub(str, "<.->", "")
    -- Hapus spasi berlebih di awal/akhir
    clean = string.match(clean, "^%s*(.-)%s*$")
    return clean
end

-- 4. LOGIKA UTAMA (SCANNER)
local function updatePredictions()
    local counts = {}
    local totalFound = 0
    
    -- Target Folder (Sesuai gambar Anda)
    local farmFolder = workspace:FindFirstChild("Farm") and workspace.Farm:FindFirstChild("Farm") and workspace.Farm.Farm:FindFirstChild("Objects_Physical")
    
    if farmFolder then
        -- Cari semua TextLabel di dalam folder Objects_Physical
        for _, obj in ipairs(farmFolder:GetDescendants()) do
            -- Kita cari TextLabel yang induknya bernama "BillboardGui"
            -- Dan kakeknya bernama "ESP" (Sesuai struktur gambar Anda)
            if obj:IsA("TextLabel") and obj.Parent:IsA("BillboardGui") then
                
                -- Ambil teks asli
                local rawText = obj.Text
                
                -- Bersihkan teks dari kode warna HTML
                local petName = cleanText(rawText)
                
                -- Filter teks kosong atau placeholder
                if petName ~= "" and petName ~= "..." then
                    totalFound = totalFound + 1
                    
                    -- Masukkan ke hitungan
                    if counts[petName] then
                        counts[petName] = counts[petName] + 1
                    else
                        counts[petName] = 1
                    end
                end
            end
        end
    end

    -- 5. FORMAT TAMPILAN
    local displayText = ""
    
    -- Urutkan nama pet secara abjad
    local sortedNames = {}
    for name in pairs(counts) do table.insert(sortedNames, name) end
    table.sort(sortedNames)
    
    -- Susun teks
    for _, name in ipairs(sortedNames) do
        displayText = displayText .. "• " .. name .. ": <b>" .. counts[name] .. "</b>\n"
    end
    
    if totalFound == 0 then
        listLabel.Text = "Menunggu Script ESP..."
    else
        listLabel.Text = displayText
        -- Auto resize kotak sesuai isi teks
        local lineCount = #sortedNames
        infoBox.Size = UDim2.new(0, 180, 0, 35 + (lineCount * 15))
    end
end

-- 6. LOOPING OTOMATIS
-- Kita gunakan loop "While" agar terus update setiap detik
task.spawn(function()
    while true do
        updatePredictions()
        task.wait(1) -- Update setiap 1 detik
    end
end)
