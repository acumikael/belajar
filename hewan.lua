-- ======================================================
-- SCRIPT PENGHITUNG PET v2 (Untuk Executor)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. HAPUS GUI LAMA JIKA ADA (agar tidak duplikat saat di-execute ulang)
if player.PlayerGui:FindFirstChild("PetCounterGui_EXEC") then
    player.PlayerGui.PetCounterGui_EXEC:Destroy()
end

-- 2. MEMBUAT SEMUA ELEMEN GUI (BOX & TEKS) DARI SCRIPT
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetCounterGui_EXEC"
screenGui.Parent = player:WaitForChild("PlayerGui") -- Letakkan di PlayerGui (live)

local counterBox = Instance.new("Frame")
counterBox.Name = "CounterBox"
counterBox.Parent = screenGui
counterBox.AnchorPoint = Vector2.new(1, 1)
counterBox.Position = UDim2.new(1, -10, 1, -10) -- Posisi: Kanan Bawah
counterBox.Size = UDim2.new(0, 200, 0, 150)    -- Ukuran: 200x150 pixel
counterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
counterBox.BackgroundTransparency = 0.3
counterBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
counterBox.BorderSizePixel = 1

local displayLabel = Instance.new("TextLabel")
displayLabel.Name = "DisplayLabel"
displayLabel.Parent = counterBox
displayLabel.Size = UDim2.new(1, -10, 1, -10) -- Ukuran: Penuh (dgn padding 5px)
displayLabel.Position = UDim2.new(0, 5, 0, 5)
displayLabel.BackgroundTransparency = 1
displayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
displayLabel.TextScaled = false
displayLabel.Font = Enum.Font.Code -- Font yg bersih
displayLabel.TextSize = 14
displayLabel.TextXAlignment = Enum.TextXAlignment.Left
displayLabel.TextYAlignment = Enum.TextYAlignment.Top
displayLabel.RichText = true -- PENTING untuk format <b>
displayLabel.Text = "Menghitung pets..."

-- 3. CARI BACKPACK (SAMA SEPERTI GAMBAR)
local backpack = player:WaitForChild("Backpack")

-- 4. FUNGSI UNTUK MENGHITUNG (Sama seperti sebelumnya)
local function updatePetCount()
    
    local ageGroups = {}
    local totalPets = 0

    for _, item in ipairs(backpack:GetChildren()) do
        
        -- Mencari format [Age 1] atau [Age 10]
        local ageString = string.match(item.Name, "%[Age (%d+)%]")
        
        if ageString then
            totalPets = totalPets + 1
            local ageNumber = tonumber(ageString)
            
            if ageGroups[ageNumber] then
                ageGroups[ageNumber] = ageGroups[ageNumber] + 1
            else
                ageGroups[ageNumber] = 1
            end
        end
    end

    -- Format teks
    local displayText = "<b>Total Pets: " .. totalPets .. "</b>\n\n"
    
    local sortedAges = {}
    for ageKey in pairs(ageGroups) do
        table.insert(sortedAges, ageKey)
    end
    table.sort(sortedAges)

    for _, age in ipairs(sortedAges) do
        local count = ageGroups[age]
        displayText = displayText .. "Age " .. age .. ": " .. count .. "\n"
    end

    -- Update teks di label yang BARU KITA BUAT
    displayLabel.Text = displayText
end

-- 5. KONEKSI EVENT (Hubungkan ke backpack)
updatePetCount() -- Jalankan pertama kali
backpack.ChildAdded:Connect(updatePetCount) -- Update jika ada pet baru
backpack.ChildRemoved:Connect(updatePetCount) -- Update jika pet dihapus
