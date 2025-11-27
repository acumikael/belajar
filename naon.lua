-- ======================================================
-- SCRIPT PENGHITUNG PET & EGG v5.2 (FIXED SPACE PARSING)
-- ======================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. LIST EGG
local eggList = {
    "Paradise Egg",
    "Jungle Egg",
    "Rare Summer Egg",
    "Bug Egg",
    "Gem Egg",
    "Bee Egg"
}

local currentSelectedEgg = eggList[1] 

-- 2. RESET GUI
if player.PlayerGui:FindFirstChild("PetCounterGui_v5") then
    player.PlayerGui.PetCounterGui_v5:Destroy()
end

-- 3. SETUP GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetCounterGui_v5"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false 

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.11, 0) 
mainFrame.Size = UDim2.new(0, 200, 0, 95)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0

-- Layout Utama
local mainLayout = Instance.new("UIListLayout")
mainLayout.Parent = mainFrame
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0, 5)
mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
mainLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Labels
local petLabel = Instance.new("TextLabel")
petLabel.Parent = mainFrame
petLabel.Size = UDim2.new(0.9, 0, 0, 20)
petLabel.BackgroundTransparency = 1
petLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
petLabel.Font = Enum.Font.Code
petLabel.TextSize = 14
petLabel.Text = "Pets: ..."
petLabel.LayoutOrder = 1

local eggLabel = Instance.new("TextLabel")
eggLabel.Parent = mainFrame
eggLabel.Size = UDim2.new(0.9, 0, 0, 20)
eggLabel.BackgroundTransparency = 1
eggLabel.TextColor3 = Color3.fromRGB(255, 220, 0) 
eggLabel.Font = Enum.Font.Code
eggLabel.TextSize = 14
eggLabel.Text = "Target: 0"
eggLabel.LayoutOrder = 2

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Parent = mainFrame
dropdownBtn.Size = UDim2.new(0.9, 0, 0, 30)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Font = Enum.Font.SourceSansBold
dropdownBtn.TextSize = 14
dropdownBtn.Text = "Pilih: " .. currentSelectedEgg
dropdownBtn.LayoutOrder = 3
dropdownBtn.AutoButtonColor = true

-- Dropdown List
local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Name = "DropdownList"
dropdownList.Parent = screenGui
dropdownList.AnchorPoint = Vector2.new(0.5, 0)
dropdownList.Position = UDim2.new(0.5, 0, 0.11, 100) 
dropdownList.Size = UDim2.new(0, 200, 0, 150)
dropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropdownList.Visible = false 
dropdownList.ZIndex = 10 
dropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y 
dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownList.ScrollBarThickness = 6

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = dropdownList
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ========================================================
-- 4. BAGIAN PERBAIKAN LOGIC (PENTING)
-- ========================================================
local function getStackAmount(itemName, targetName)
    -- Jika nama item SAMA PERSIS (Berarti jumlah 1)
    if itemName == targetName then 
        return 1 
    end
    
    -- Escape karakter spesial (agar aman)
    local escapedTarget = string.gsub(targetName, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    
    -- PERBAIKAN: Menambahkan %s* (artinya: boleh ada spasi atau tidak) sebelum huruf x
    -- Pola: "Bug Egg" + (Spasi Bebas) + "x" + (Angka)
    local matchAmount = string.match(itemName, "^" .. escapedTarget .. "%s*x(%d+)$")
    
    if matchAmount then 
        return tonumber(matchAmount) 
    end
    
    return 0
end
-- ========================================================

local function updateStats(backpack)
    if not backpack then return end
    
    local totalPets = 0
    local totalTargetEgg = 0
    
    for _, item in ipairs(backpack:GetChildren()) do
        -- Hitung Pet
        if string.match(item.Name, "%[Age (%d+)%]") then
            totalPets = totalPets + 1
        end
        
        -- Hitung Egg dengan Logic Baru
        local amount = getStackAmount(item.Name, currentSelectedEgg)
        totalTargetEgg = totalTargetEgg + amount
    end
    
    petLabel.Text = "Total Pets: " .. totalPets
    eggLabel.Text = currentSelectedEgg .. ": " .. totalTargetEgg
end

-- 5. ISI DROPDOWN
for _, eggName in ipairs(eggList) do
    local btn = Instance.new("TextButton")
    btn.Parent = dropdownList
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Text = eggName
    btn.ZIndex = 11

    btn.MouseButton1Click:Connect(function()
        currentSelectedEgg = eggName
        dropdownBtn.Text = "Pilih: " .. eggName
        dropdownList.Visible = false 
        
        local bp = player:FindFirstChild("Backpack")
        if bp then updateStats(bp) end
    end)
end

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownList.Visible = not dropdownList.Visible
end)

-- 6. RUN
task.spawn(function()
    local backpack = player:FindFirstChild("Backpack")
    while not backpack do
        petLabel.Text = "Menunggu..."
        task.wait(1)
        backpack = player:FindFirstChild("Backpack")
    end

    backpack.ChildAdded:Connect(function() updateStats(backpack) end)
    backpack.ChildRemoved:Connect(function() updateStats(backpack) end)
    
    -- Hitung loop cepat agar responsif kalau item nambah cepat
    while task.wait(0.5) do
        updateStats(backpack)
    end
end)
