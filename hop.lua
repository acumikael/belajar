--// GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerInfoGUI_RobloxURL"
if game.CoreGui:FindFirstChild("ServerInfoGUI_RobloxURL") then
    game.CoreGui:FindFirstChild("ServerInfoGUI_RobloxURL"):Destroy()
end

-- Coba pasang di CoreGui
local success, _ = pcall(function() ScreenGui.Parent = game.CoreGui end)
if not success then ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 180)
Frame.Position = UDim2.new(0.5, -175, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "ORIGINAL URL HOP"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Parent = Frame

-- Elemen status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 145)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusLabel.Parent = Frame

local HopButton = Instance.new("TextButton")
HopButton.Size = UDim2.new(0.8, 0, 0, 40)
HopButton.Position = UDim2.new(0.1, 0, 0, 80)
HopButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80) -- Merah (Original URL)
HopButton.Text = "HOP SERVER (Roblox URL)"
HopButton.TextColor3 = Color3.fromRGB(255,255,255)
HopButton.Font = Enum.Font.GothamBold
HopButton.TextSize = 16
HopButton.Parent = Frame
local UICornerBtn = Instance.new("UICorner", HopButton)
UICornerBtn.CornerRadius = UDim.new(0, 8)

--// LOGIC HOP SERVER
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local PlaceId = game.PlaceId
local JobId = game.JobId

local function HopServer()
    StatusLabel.Text = "Scanning (Roblox.com)..."
    HopButton.Active = false
    
    local cursor = ""
    local found = false
    
    -- MENGGUNAKAN URL ASLI ROBLOX
    local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100&cursor="
    
    task.spawn(function()
        while not found do
            local reqUrl = url .. cursor
            
            -- Request ke Roblox.com
            local success, response = pcall(function() return game:HttpGet(reqUrl) end)
            
            if success then
                local data = HttpService:JSONDecode(response)
                
                if data and data.data then
                    for _, server in pairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= JobId then
                            
                            -- FOUND!
                            found = true
                            StatusLabel.Text = "Found! Waiting 3s..."
                            
                            -- Jeda agar Delta tidak mendeteksi spam teleport
                            task.wait(3) 
                            
                            StatusLabel.Text = "Teleporting..."
                            
                            local tpResult = pcall(function()
                                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, Players.LocalPlayer)
                            end)
                            
                            if not tpResult then
                                 StatusLabel.Text = "Teleport Blocked/Failed"
                                 HopButton.Active = true
                            end
                            return
                        end
                    end
                    
                    if data.nextPageCursor then
                        cursor = data.nextPageCursor
                        task.wait(0.5)
                    else
                        StatusLabel.Text = "No empty servers found."
                        HopButton.Active = true
                        break
                    end
                else
                    StatusLabel.Text = "Invalid Data Recieved"
                    HopButton.Active = true
                    break
                end
            else
                -- INI YANG AKAN MUNCUL JIKA ROBLOX MEMBLOKIR REQUEST
                StatusLabel.Text = "Error: Blocked by Roblox"
                warn("HTTP Error (Roblox Block): " .. tostring(response))
                HopButton.Active = true
                break
            end
        end
    end)
end

HopButton.MouseButton1Click:Connect(HopServer)
