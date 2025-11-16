-- ======================================================
-- SCRIPT PENGHITUNG PET v4 (Sangat Simpel)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. HAPUS GUI LAMA JIKA ADA
if player.PlayerGui:FindFirstChild("PetCounterGui_EXEC") then
    player.PlayerGui.PetCounterGui_EXEC:Destroy()
end

-- 2. MEMBUAT ELEMEN GUI (BOX & TEKS) - Ukuran lebih kecil
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetCounterGui_EXEC"
screenGui.Parent = player:WaitForChild("PlayerGui")

local counterBox = Instance.new("Frame")
counterBox.Name = "CounterBox"
counterBox.Parent = screenGui
counterBox.AnchorPoint = Vector2.new(1, 1)
counterBox.Position = UDim2.new(1, -10, 1, -10) -- Kanan Bawah
counterBox.Size = UDim2.new(0, 150, 0, 40)    -- <-- SUPER KECIL
counterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
counterBox.BackgroundTransparency = 0.3
counterBox.BorderColor3 = Color3.fromRGB(255, 255, 255)

local displayLabel = Instance.new("TextLabel")
displayLabel.Name = "DisplayLabel"
displayLabel.Parent = counterBox
displayLabel.Size = UDim2.new(1, 0, 1, 0) -- Penuhi frame
displayLabel.BackgroundTransparency = 1
displayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
displayLabel.Font = Enum.Font.Code
displayLabel.TextSize = 16
displayLabel.TextXAlignment = Enum.TextXAlignment.Center -- Teks di tengah
displayLabel.TextYAlignment = Enum.TextYAlignment.Center -- Teks di tengah
displayLabel.Text = "Mencari..."

-- 3. FUNGSI UNTUK MENGHITUNG (Versi Simpel)
local function updatePetCount(backpack)
    if not backpack then return end 

    local totalPets = 0

    -- Loop semua item di backpack
    for _, item in ipairs(backpack:GetChildren()) do
        
        -- Kita tetap harus cek 'Age' untuk membedakan pet dari item lain
        if string.match(item.Name, "%[Age (%d+)%]") then
            totalPets = totalPets + 1
        end
    end

    -- Langsung tampilkan totalnya
    displayLabel.Text = "Total Pets: " .. totalPets
end


-- 4. LOGIKA UNTUK MENUNGGU 'Backpack' (Sama seperti v3)
task.spawn(function()
    
    local backpack = player:FindFirstChild("Backpack")
    
    while not backpack do
        displayLabel.Text = "Menunggu..."
        task.wait(1) 
        backpack = player:FindFirstChild("Backpack")
    end

    -- 5. JIKA SUDAH KETEMU, HUBUNGKAN EVENT & HITUNG
    
    -- Hubungkan 'listener'
    backpack.ChildAdded:Connect(function() updatePetCount(backpack) end)
    backpack.ChildRemoved:Connect(function() updatePetCount(backpack) end)
    
    -- Hitung pertama kali
    updatePetCount(backpack)
end)
