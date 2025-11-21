-- ======================================================
-- EGG SPY v2 - GUI LOGGER EDITION (KHUSUS DELTA)
-- ======================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- 1. MEMBERSIHKAN GUI LAMA
if getgenv().SpyGui then getgenv().SpyGui:Destroy() end

-- 2. MEMBUAT LAYAR LOG (GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggSpyOverlay"
screenGui.Parent = CoreGui -- Masuk ke CoreGui agar tidak tertutup UI game
getgenv().SpyGui = screenGui

local logFrame = Instance.new("ScrollingFrame")
logFrame.Name = "LogWindow"
logFrame.Parent = screenGui
logFrame.Position = UDim2.new(0.6, 0, 0.3, 0) -- Posisi di Kanan Tengah
logFrame.Size = UDim2.new(0.35, 0, 0.4, 0) -- Ukuran Kotak
logFrame.BackgroundColor3 = Color3.new(0, 0, 0)
logFrame.BackgroundTransparency = 0.3
logFrame.CanvasSize = UDim2.new(0, 0, 10, 0) -- Bisa discroll
logFrame.ScrollBarThickness = 6

-- Judul
local title = Instance.new("TextLabel")
title.Parent = screenGui
title.Position = UDim2.new(0.6, 0, 0.25, 0)
title.Size = UDim2.new(0.35, 0, 0.05, 0)
title.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
title.Text = "EGG SPY LOG"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.Code
title.TextScaled = true

-- 3. FUNGSI LOG MANUAL (Mencetak teks ke layar HP)
local function Log(text, color)
    local label = Instance.new("TextLabel")
    label.Parent = logFrame
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, (#logFrame:GetChildren() - 1) * 20)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Font = Enum.Font.Code
    label.TextSize = 12
    
    -- Auto scroll ke bawah
    logFrame.CanvasPosition = Vector2.new(0, 9999)
end

Log("Script dimulai...", Color3.fromRGB(0, 255, 0))

-- 4. LOGIKA UTAMA (SCANNING)
task.spawn(function()
    -- Coba akses folder
    local success, result = pcall(function()
        return workspace.Farm.Farm.Objects_Physical
    end)

    if not success or not result then
        Log("ERROR: Folder tidak ketemu!", Color3.fromRGB(255, 0, 0))
        Log("Coba cek ulang nama folder.", Color3.fromRGB(255, 0, 0))
        return
    end

    local physicalFolder = result
    Log("Folder 'Objects_Physical' OK!", Color3.fromRGB(0, 255, 0))
    Log("Sedang memantau telur...", Color3.fromRGB(255, 255, 0))

    local eggCount = 0

    -- Scan semua telur
    for _, eggModel in ipairs(physicalFolder:GetDescendants()) do
        if eggModel:IsA("Model") and string.find(eggModel.Name, "Egg") then
            eggCount = eggCount + 1
            
            -- Pasang pendengar (Listener)
            eggModel.ChildAdded:Connect(function(child)
                Log("DETECT: Ada yg masuk ke " .. eggModel.Name, Color3.fromRGB(0, 255, 255))
                Log(" > Nama: " .. child.Name, Color3.fromRGB(255, 255, 255))
                Log(" > Tipe: " .. child.ClassName, Color3.fromRGB(200, 200, 200))
            end)

            eggModel.DescendantAdded:Connect(function(descendant)
                -- Filter spam
                if descendant.Name ~= "Part" and descendant.Name ~= "TouchInterest" then
                    Log("DEEP: " .. descendant.Name .. " (di " .. eggModel.Name .. ")", Color3.fromRGB(255, 170, 0))
                end
            end)
        end
    end

    Log("Memantau " .. eggCount .. " telur.", Color3.fromRGB(0, 255, 0))
    Log("Silakan Buka Telur sekarang!", Color3.fromRGB(255, 255, 255))
end)
