-- ======================================================
-- SCRIPT PENGHITUNG PET & FRUIT v4
-- ======================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- MODE: "pets" atau "fruits"
local MODE = "pets" -- <-- GANTI DI SINI

-- ======================================================

if player.PlayerGui:FindFirstChild("PetCounterGui_EXEC") then
    player.PlayerGui.PetCounterGui_EXEC:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetCounterGui_EXEC"
screenGui.Parent = player:WaitForChild("PlayerGui")

local counterBox = Instance.new("Frame")
counterBox.Name = "CounterBox"
counterBox.Parent = screenGui
counterBox.AnchorPoint = Vector2.new(0.5, 0)
counterBox.Position = UDim2.new(0.5, 0, 0.11, 0)
counterBox.Size = UDim2.new(0, 150, 0, 40)
counterBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
counterBox.BackgroundTransparency = 0.3
counterBox.BorderColor3 = Color3.fromRGB(255, 255, 255)

local displayLabel = Instance.new("TextLabel")
displayLabel.Name = "DisplayLabel"
displayLabel.Parent = counterBox
displayLabel.Size = UDim2.new(1, 0, 1, 0)
displayLabel.BackgroundTransparency = 1
displayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
displayLabel.Font = Enum.Font.Code
displayLabel.TextSize = 16
displayLabel.TextXAlignment = Enum.TextXAlignment.Center
displayLabel.TextYAlignment = Enum.TextYAlignment.Center
displayLabel.Text = "Mencari..."

-- 3. FUNGSI HITUNG BERDASARKAN MODE
local function updateCount(backpack)
    if not backpack then return end

    if MODE == "pets" then
        -- Hitung Pets berdasarkan parameter Age
        local totalPets = 0
        for _, item in ipairs(backpack:GetChildren()) do
            if string.match(item.Name, "%[Age (%d+)%]") then
                totalPets = totalPets + 1
            end
        end
        displayLabel.Text = "Total Pets: " .. totalPets

    elseif MODE == "fruits" then
        -- Hitung total KG semua Fruits
        local totalKG = 0
        for _, item in ipairs(backpack:GetChildren()) do
            local kg = string.match(item.Name, "%(([%d%.]+) KG%)")
            if kg then
                totalKG = totalKG + tonumber(kg)
            end
        end
        -- Tampilkan dengan 2 desimal
        displayLabel.Text = string.format("Total: %.2f KG", totalKG)
    end
end

-- 4. TUNGGU BACKPACK
task.spawn(function()
    local backpack = player:FindFirstChild("Backpack")

    while not backpack do
        displayLabel.Text = "Menunggu..."
        task.wait(1)
        backpack = player:FindFirstChild("Backpack")
    end

    backpack.ChildAdded:Connect(function() updateCount(backpack) end)
    backpack.ChildRemoved:Connect(function() updateCount(backpack) end)

    updateCount(backpack)
end)
