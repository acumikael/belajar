--// GUI SETUP (Bagian ini tidak berubah, hanya dirapikan sedikit)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerInfoGUI"
if game.CoreGui:FindFirstChild("ServerInfoGUI") then
    game.CoreGui:FindFirstChild("ServerInfoGUI"):Destroy() -- Hapus gui lama jika ada
end
-- Note: Untuk executor, lebih aman taruh di CoreGui agar tidak hilang saat mati/respawn
-- Jika Delta error akses CoreGui, kembalikan ke PlayerGui
local success, _ = pcall(function() ScreenGui.Parent = game.CoreGui end)
if not success then ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 180)
Frame.Position = UDim2.new(0.5, -175, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true -- Agar GUI bisa digeser

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "SERVER LINK & HOP"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Parent = Frame

local Input = Instance.new("TextBox")
Input.Size = UDim2.new(1, -20, 0, 40)
Input.Position = UDim2.new(0, 10, 0, 50)
Input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Input.TextColor3 = Color3.fromRGB(255,255,255)
Input.Font = Enum.Font.Gotham
Input.TextSize = 14
Input.TextXAlignment = Enum.TextXAlignment.Left
Input.ClearTextOnFocus = false
Input.Parent = Frame

local UICorner2 = Instance.new("UICorner", Input)
UICorner2.CornerRadius = UDim.new(0, 8)

local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0.45, -10, 0, 40)
CopyButton.Position = UDim2.new(0.05, 0, 0, 100)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
CopyButton.Text = "Copy Link"
CopyButton.TextColor3 = Color3.fromRGB(255,255,255)
CopyButton.Font = Enum.Font.GothamBold
CopyButton.TextSize = 16
CopyButton.Parent = Frame

local UICorner3 = Instance.new("UICorner", CopyButton)
UICorner3.CornerRadius = UDim.new(0, 8)

local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(0.45, -10, 0, 40)
HopButton.Position = UDim2.new(0.5, 0, 0, 100)
HopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
HopButton.Text = "Hop Server"
HopButton.TextColor3 = Color3.fromRGB(255,255,255)
HopButton.Font = Enum.Font.GothamBold
HopButton.TextSize = 16
HopButton.Parent = Frame

local UICorner4 = Instance.new("UICorner", HopButton)
UICorner4.CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 145)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.Parent = Frame

--// GENERATE SERVER LINK
local placeId = game.PlaceId
local jobId = game.JobId
local serverLink = "https://www.roblox.com/games/" .. placeId .. "?serverId=" .. jobId
Input.Text = serverLink

--// COPY LINK
CopyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(serverLink)
        StatusLabel.Text = "Link copied to clipboard!"
        wait(2)
        StatusLabel.Text = "Ready"
    else
        StatusLabel.Text = "Executor not support setclipboard"
    end
end)

--// HOP SERVER LOGIC (DIPERBAIKI)
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local function HopServer()
    StatusLabel.Text = "Searching server..."
    HopButton.Active = false -- Disable tombol biar ga spam
    
    local cursor = ""
    local found = false
    
    -- Loop sederhana untuk mencari server
    while not found do
        -- PERBAIKAN: Menggunakan roproxy.com agar tidak diblokir
        local url = "https://games.roproxy.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100&cursor=" .. cursor
        
        local success, response = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success then
            local data = HttpService:JSONDecode(response)
            
            -- Loop list server yang didapat
            for _, server in pairs(data.data) do
                -- Logic: Server tidak sama dengan server sekarang DAN server belum penuh
                if server.playing < server.maxPlayers and server.id ~= jobId then
                    StatusLabel.Text = "Joining: " .. server.playing .. "/" .. server.maxPlayers
                    
                    local tpSuccess, tpErr = pcall(function()
                        TeleportService:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
                    end)
                    
                    if tpSuccess then
                        found = true
                        return -- Berhenti mencari
                    end
                end
            end
            
            -- Jika tidak ketemu di page ini, cek page berikutnya
            if data.nextPageCursor then
                cursor = data.nextPageCursor
            else
                StatusLabel.Text = "No other servers found!"
                HopButton.Active = true
                break
            end
        else
            StatusLabel.Text = "HTTP Error (Proxy Fail)"
            warn("Hop Error: " .. tostring(response))
            HopButton.Active = true
            break
        end
        task.wait(0.1) -- Delay sedikit biar tidak crash
    end
end

HopButton.MouseButton1Click:Connect(function()
    HopServer()
end)
