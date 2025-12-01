--// GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerInfoGUI"
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 180)
Frame.Position = UDim2.new(0.5, -175, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "SERVER LINK"
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


--// GENERATE SERVER LINK
local placeId = game.PlaceId
local jobId = game.JobId

-- Format link server
local serverLink = "https://www.roblox.com/games/" .. placeId .. "?serverId=" .. jobId

-- Tampilkan ke TextBox
Input.Text = serverLink


--// COPY LINK
CopyButton.MouseButton1Click:Connect(function()
    setclipboard(serverLink)

    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Copied!";
        Text = "Server link disalin ke clipboard.";
        Duration = 2
    })
end)


--// HOP SERVER (Cari server baru dengan 0 player atau random)
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local function HopServer()
    local servers = {}
    local cursor = ""

    -- CARI SERVER LAIN
    pcall(function()
        local req = game:HttpGet(
            "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100&cursor="..cursor
        )
        local data = HttpService:JSONDecode(req)
        servers = data.data
    end)

    for _, server in pairs(servers) do
        if server.id ~= jobId and server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
            return
        end
    end
end

-- Tombol Hop
HopButton.MouseButton1Click:Connect(function()
    HopServer()
end)
