-- ======================================================
-- SCRIPT PENGHITUNG PET & EGG v5.1 (FIXED DROPDOWN)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. LIST EGG (Bisa ditambah sendiri)
local eggList = {
    "Paradise Egg",
    "Jungle Egg",
    "Rare Summer Egg",
    "Bug Egg",
    "Gem Egg",
    "Bee Egg"
}

local currentSelectedEgg = eggList[1] -- Default

-- 2. BERSIHKAN GUI LAMA
if player.PlayerGui:FindFirstChild("PetCounterGui_v5") then
    player.PlayerGui.PetCounterGui_v5:Destroy()
end

-- 3. BUAT GUI BARU
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetCounterGui_v5"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false -- Agar GUI tidak hilang saat mati

-- FRAME UTAMA (Kotak Status)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.11, 0) -- Posisi Atas Tengah
mainFrame.Size = UDim2.new(0, 200, 0, 95)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.2

-- LAYOUT FRAME UTAMA
local mainLayout = Instance.new("UIListLayout")
mainLayout.Parent = mainFrame
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0, 5)
mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
mainLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- LABEL PET
local petLabel = Instance.new("TextLabel")
petLabel.Name = "PetLabel"
petLabel.Parent = mainFrame
petLabel.Size = UDim2.new(0.9, 0, 0, 20)
petLabel.BackgroundTransparency = 1
petLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
petLabel.Font = Enum.Font.Code
petLabel.TextSize = 14
petLabel.Text = "Pets: Loading..."
petLabel.LayoutOrder = 1

-- LABEL EGG
local eggLabel = Instance.new("TextLabel")
eggLabel.Name = "EggLabel"
eggLabel.Parent = mainFrame
eggLabel.Size = UDim2.new(0.9, 0, 0, 20)
eggLabel.BackgroundTransparency = 1
eggLabel.TextColor3 = Color3.fromRGB(255, 220, 0) -- Kuning Emas
eggLabel.Font = Enum.Font.Code
eggLabel.TextSize = 14
eggLabel.Text = "Target: 0"
eggLabel.LayoutOrder = 2

-- TOMBOL BUKA DROPDOWN
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Name = "DropdownBtn"
dropdownBtn.Parent = mainFrame
dropdownBtn.Size = UDim2.new(0.9, 0, 0, 30)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Font = Enum.Font.SourceSansBold
dropdownBtn.TextSize = 14
dropdownBtn.Text = "Pilih: " .. currentSelectedEgg
dropdownBtn.LayoutOrder = 3
dropdownBtn.AutoButtonColor = true

-- FRAME DROPDOWN LIST (Pop-up Menu)
-- Kita taruh di ScreenGui langsung agar tidak terpotong (Clip)
local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Name = "DropdownList"
dropdownList.Parent = screenGui
dropdownList.AnchorPoint = Vector2.new(0.5, 0)
-- Posisi tepat di bawah MainFrame (0.11 + offset sedikit)
dropdownList.Position = UDim2.new(0.5, 0, 0.11, 100) 
dropdownList.Size = UDim2.new(0, 200, 0, 150) -- Tinggi list
dropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropdownList.BorderColor3 = Color3.fromRGB(100, 100, 100)
dropdownList.Visible = false -- Default Sembunyi
dropdownList.ZIndex = 10 -- Paling depan
dropdownList.ScrollBarThickness = 6

-- FITUR PENTING AGAR TIDAK BLANK:
dropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Otomatis panjang ke bawah
dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = dropdownList
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 4. FUNGSI LOGIKA (HITUNG EGG STACK & PET)
local function getStackAmount(itemName, targetName)
    if itemName == targetName then return 1 end
    
    local escapedTarget = string.gsub(targetName, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    local matchAmount = string.match(itemName, "^" .. escapedTarget .. "x(%d+)$")
    
    if matchAmount then return tonumber(matchAmount) end
    return 0
end

local function updateStats(backpack)
    if not backpack then return end
    
    local totalPets = 0
    local totalTargetEgg = 0
    
    for _, item in ipairs(backpack:GetChildren()) do
        -- Hitung Pet (Cek Age)
        if string.match(item.Name, "%[Age (%d+)%]") then
            totalPets = totalPets + 1
        end
        
        -- Hitung Egg (Cek Nama & Stack)
        local amount = getStackAmount(item.Name, currentSelectedEgg)
        totalTargetEgg = totalTargetEgg + amount
    end
    
    petLabel.Text = "Total Pets: " .. totalPets
    eggLabel.Text = currentSelectedEgg .. ": " .. totalTargetEgg
end

-- 5. MEMBUAT ITEM DI DALAM DROPDOWN
for _, eggName in ipairs(eggList) do
    local btn = Instance.new("TextButton")
    btn.Parent = dropdownList
    btn.Size = UDim2.new(1, 0, 0, 30) -- Tinggi tiap tombol
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Text = eggName
    btn.ZIndex = 11
    
    -- Efek visual selang-seling (Opsional)
    -- btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

    btn.MouseButton1Click:Connect(function()
        currentSelectedEgg = eggName
        dropdownBtn.Text = "Pilih: " .. eggName
        dropdownList.Visible = false -- Tutup menu
        
        -- Refresh Hitungan
        local bp = player:FindFirstChild("Backpack")
        if bp then updateStats(bp) end
    end)
end

-- EVENT KLIK TOMBOL UTAMA
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownList.Visible = not dropdownList.Visible
end)

-- 6. LOOP UTAMA
task.spawn(function()
    local backpack = player:FindFirstChild("Backpack")
    while not backpack do
        petLabel.Text = "Menunggu..."
        task.wait(1)
        backpack = player:FindFirstChild("Backpack")
    end

    backpack.ChildAdded:Connect(function() updateStats(backpack) end)
    backpack.ChildRemoved:Connect(function() updateStats(backpack) end)
    
    updateStats(backpack)
end)
