-- ======================================================
-- SCRIPT PENGHITUNG PET & EGG v5 (Dropdown & Stack Logic)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. KONFIGURASI DAFTAR EGG (JSON STYLE)
-- Kamu bisa menambah atau menghapus nama egg di sini
local eggList = {
    "Paradise Egg",
    "Jungle Egg",
    "Rare Summer Egg",
    "Bug Egg",
    "Gem Egg",
    "Bee Egg"
}

-- Variabel untuk menyimpan egg yang sedang dipilih user
local currentSelectedEgg = eggList[1] -- Default pilih yang pertama

-- 2. HAPUS GUI LAMA
if player.PlayerGui:FindFirstChild("PetCounterGui_v5") then
    player.PlayerGui.PetCounterGui_v5:Destroy()
end

-- 3. MEMBUAT GUI (Main Frame & Dropdown)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetCounterGui_v5"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.11, 0)
mainFrame.Size = UDim2.new(0, 200, 0, 90) -- Lebih besar untuk muat tombol
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false -- Agar dropdown bisa keluar frame

-- UI List Layout (Agar rapi ke bawah)
local layout = Instance.new("UIListLayout")
layout.Parent = mainFrame
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Label Total Pet
local petLabel = Instance.new("TextLabel")
petLabel.Name = "PetLabel"
petLabel.Parent = mainFrame
petLabel.Size = UDim2.new(1, 0, 0, 25)
petLabel.BackgroundTransparency = 1
petLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
petLabel.Font = Enum.Font.Code
petLabel.TextSize = 14
petLabel.Text = "Pets: Loading..."
petLabel.LayoutOrder = 1

-- Label Total Egg (Target)
local eggLabel = Instance.new("TextLabel")
eggLabel.Name = "EggLabel"
eggLabel.Parent = mainFrame
eggLabel.Size = UDim2.new(1, 0, 0, 25)
eggLabel.BackgroundTransparency = 1
eggLabel.TextColor3 = Color3.fromRGB(255, 255, 100) -- Warna kuning biar beda
eggLabel.Font = Enum.Font.Code
eggLabel.TextSize = 14
eggLabel.Text = "Egg: 0"
eggLabel.LayoutOrder = 2

-- Tombol Dropdown
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Name = "DropdownBtn"
dropdownBtn.Parent = mainFrame
dropdownBtn.Size = UDim2.new(0.9, 0, 0, 25)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Font = Enum.Font.SourceSansBold
dropdownBtn.Text = "Pilih Egg: " .. currentSelectedEgg
dropdownBtn.LayoutOrder = 3

-- Frame List Dropdown (Sembunyi di awal)
local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Name = "ListFrame"
dropdownList.Parent = mainFrame
dropdownList.Size = UDim2.new(0.9, 0, 0, 100)
dropdownList.Position = UDim2.new(0.05, 0, 1, 5) -- Di bawah main frame
dropdownList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
dropdownList.Visible = false -- Hidden default
dropdownList.ScrollBarThickness = 4
dropdownList.ZIndex = 5

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = dropdownList
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 4. FUNGSI LOGIKA PERHITUNGAN

-- Fungsi Parse String (Membaca "Bug Eggx188")
local function getStackAmount(itemName, targetName)
    -- Cek 1: Apakah nama item persis sama? (Jumlah 1)
    if itemName == targetName then
        return 1
    end
    
    -- Cek 2: Apakah formatnya "NamaTargetxANGKA"?
    -- escape string pattern magic characters
    local escapedTarget = string.gsub(targetName, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    
    -- Pola regex: Dimulai dengan nama egg, lalu "x", lalu angka
    local matchAmount = string.match(itemName, "^" .. escapedTarget .. "x(%d+)$")
    
    if matchAmount then
        return tonumber(matchAmount) -- Kembalikan angka (misal 188)
    end
    
    return 0 -- Bukan item yang dicari
end

local function updateStats(backpack)
    if not backpack then return end
    
    local totalPets = 0
    local totalTargetEgg = 0
    
    for _, item in ipairs(backpack:GetChildren()) do
        -- A. LOGIKA PET (Cek Age)
        if string.match(item.Name, "%[Age (%d+)%]") then
            totalPets = totalPets + 1
        end
        
        -- B. LOGIKA EGG (Cek Nama & Stack xAmount)
        local amount = getStackAmount(item.Name, currentSelectedEgg)
        totalTargetEgg = totalTargetEgg + amount
    end
    
    -- Update Teks GUI
    petLabel.Text = "Total Pets: " .. totalPets
    eggLabel.Text = currentSelectedEgg .. ": " .. totalTargetEgg
end

-- 5. MEMBUAT ISI DROPDOWN
for _, eggName in ipairs(eggList) do
    local btn = Instance.new("TextButton")
    btn.Parent = dropdownList
    btn.Size = UDim2.new(1, 0, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Text = eggName
    
    -- Ketika Egg dipilih dari list
    btn.MouseButton1Click:Connect(function()
        currentSelectedEgg = eggName
        dropdownBtn.Text = "Pilih: " .. eggName
        dropdownList.Visible = false -- Tutup list
        
        -- Langsung update hitungan
        local bp = player:FindFirstChild("Backpack")
        if bp then updateStats(bp) end
    end)
end

-- Toggle Dropdown saat tombol diklik
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownList.Visible = not dropdownList.Visible
end)

-- 6. LOOP UTAMA (WAIT FOR BACKPACK)
task.spawn(function()
    local backpack = player:FindFirstChild("Backpack")
    while not backpack do
        petLabel.Text = "Menunggu Backpack..."
        task.wait(1)
        backpack = player:FindFirstChild("Backpack")
    end

    -- Listener jika item bertambah/berkurang
    backpack.ChildAdded:Connect(function() updateStats(backpack) end)
    backpack.ChildRemoved:Connect(function() updateStats(backpack) end)
    
    -- Hitung awal
    updateStats(backpack)
end)
