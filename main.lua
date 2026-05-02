local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

pcall(function()
    setclipboard("https://discord.gg/uevZf2qtM")
end)

local Window = Rayfield:CreateWindow({
   Name = "Ashly",
   LoadingTitle = "Ashly Scrip",
   LoadingSubtitle = "by Ashe",
   ToggleUIKeybind = "K",
   ConfigurationSaving = {Enabled = true, FolderName = "MyScript"},
   Discord = {
      Enabled = true,
      Invite = "uevZf2qtM",
      RememberJoins = true
   },
   KeySystem = true,
   KeySettings = {
      Title = "Ashly Key System",
      Subtitle = "Key in Discord",
      Note = "Link copied to clipboard! (discord.gg/uevZf2qtM)",
      FileName = "AshlyKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Ashlythebest1"}
   }
})

local Tab = Window:CreateTab("Main", 4483362458)

Tab:CreateButton({
   Name = "Join Our Discord",
   Callback = function()
      setclipboard("https://discord.gg/uevZf2qtM")
      Rayfield:Notify({
         Title = "Discord",
         Content = "Link copied to clipboard! Opening Discord...",
         Duration = 5,
         Image = 4483362458,
      })
      local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
      if req then
         pcall(function()
            req({
               Url = 'http://127.0.0.1:6463/rpc?v=1',
               Method = 'POST',
               Headers = {
                  ['Content-Type'] = 'application/json',
                  Origin = 'https://discord.com'
               },
               Body = game:GetService('HttpService'):JSONEncode({
                  cmd = 'INVITE_BROWSER',
                  nonce = game:GetService('HttpService'):GenerateGUID(false),
                  args = {code = 'uevZf2qtM'}
               })
            })
         end)
      end
   end,
})

Tab:CreateSection("ESP")
local ESPEnabled = false
local ChamsEnabled = false
local EnemyOnly = false

local Tab2 = Window:CreateTab("Aimbot", 4483362458)
Tab2:CreateSection("Aimbot")
local AimbotEnabled = true
local AimbotSmoothness = 4
local FOVEnabled = false
local FOVRadius = 100

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false

local ESPObjects = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local AimbotTarget = nil

-- Get closest character (handles custom workspace characters)
local function GetCharacter(player)
    if not player then return nil end
    local char = player.Character
    if char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("Humanoid")) then 
        return char 
    end
    
    local wsChar = workspace:FindFirstChild(player.Name)
    if wsChar and wsChar:IsA("Model") and (wsChar:FindFirstChild("HumanoidRootPart") or wsChar:FindFirstChildOfClass("Humanoid")) then
        return wsChar
    end

    for _, obj in pairs(player:GetChildren()) do
        if obj:IsA("Model") and (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("Humanoid")) then
            return obj
        end
    end
    return nil
end

local function GetRootPart(char)
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then return root end
    root = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if root then return root end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(char)
    if not char then return false end
    local hum = GetHumanoid(char)
    if hum then return hum.Health > 0 end
    local root = GetRootPart(char)
    return root ~= nil
end

local function IsEnemy(player)
    if not player or not LocalPlayer then return false end
    
    -- If either player is neutral (FFA mode), they are an enemy
    if LocalPlayer.Neutral or player.Neutral then
        return true
    end

    -- If they are on actual Teams, compare them
    if LocalPlayer.Team ~= nil and player.Team ~= nil then 
        return LocalPlayer.Team ~= player.Team 
    end
    
    return true
end

local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Box then obj.Box:Remove() end
        if obj.Name then obj.Name:Remove() end
        if obj.Highlight then obj.Highlight:Destroy() end
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then
        if ESPObjects[player].Box then ESPObjects[player].Box:Remove() end
        if ESPObjects[player].Name then ESPObjects[player].Name:Remove() end
        if ESPObjects[player].Highlight then ESPObjects[player].Highlight:Destroy() end
    end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Visible = false

    local nameText = Drawing.new("Text")
    nameText.Size = 16
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Outline = true
    nameText.Center = true
    nameText.Visible = false

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    
    local coreGui = game:GetService("CoreGui")
    if coreGui then
        pcall(function() highlight.Parent = coreGui end)
    end
    if not highlight.Parent then
        highlight.Parent = workspace
    end

    ESPObjects[player] = {Box = box, Name = nameText, Highlight = highlight}
end

-- Refresh ESP for all players (call when a new character loads)
local function RefreshAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
end

-- äş Update loop — ESP + Aimbot target selection
RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    -- == ESP & Chams ==
    if ESPEnabled or ChamsEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then
                if ESPObjects[player] then
                    ESPObjects[player].Box.Visible = false
                    ESPObjects[player].Name.Visible = false
                    if ESPObjects[player].Highlight then ESPObjects[player].Highlight.Enabled = false end
                end
                continue
            end
            
            local isEnemy = IsEnemy(player)
            if EnemyOnly and not isEnemy then
                if ESPObjects[player] then
                    ESPObjects[player].Box.Visible = false
                    ESPObjects[player].Name.Visible = false
                    if ESPObjects[player].Highlight then ESPObjects[player].Highlight.Enabled = false end
                end
                continue
            end
            
            if not ESPObjects[player] then CreateESP(player) end

            local char = GetCharacter(player)
            local root = GetRootPart(char)
            local alive = IsAlive(char)
            local obj = ESPObjects[player]

            if root and alive then
                -- Calculate Distance in meters (1 stud is approx 0.28 meters)
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local distMeters = math.floor(dist * 0.28)
                
                -- Chams
                if ChamsEnabled and obj.Highlight then
                    if obj.Highlight.Adornee ~= char then
                        obj.Highlight.Adornee = char
                    end
                    obj.Highlight.Enabled = true
                    if isEnemy then
                        obj.Highlight.FillColor = Color3.fromRGB(0, 255, 0)
                        obj.Highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                    else
                        obj.Highlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan for teammates
                        obj.Highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
                    end
                else
                    if obj.Highlight then obj.Highlight.Enabled = false end
                end

                -- ESP Box and Text
                if ESPEnabled then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local size = Vector2.new(4000 / pos.Z, 6000 / pos.Z)
                        obj.Box.Size = size
                        obj.Box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                        
                        if isEnemy then
                            obj.Box.Color = Color3.fromRGB(0, 255, 0) -- Green for enemies
                            obj.Name.Color = Color3.fromRGB(0, 255, 0)
                        else
                            obj.Box.Color = Color3.fromRGB(0, 255, 255) -- Cyan for teammates
                            obj.Name.Color = Color3.fromRGB(0, 255, 255)
                        end
                        
                        obj.Box.Visible = true
                        obj.Name.Text = player.Name .. " [" .. distMeters .. "m]"
                        obj.Name.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 20)
                        obj.Name.Visible = true
                    else
                        obj.Box.Visible = false
                        obj.Name.Visible = false
                    end
                else
                    obj.Box.Visible = false
                    obj.Name.Visible = false
                end
            else
                obj.Box.Visible = false
                obj.Name.Visible = false
                if obj.Highlight then obj.Highlight.Enabled = false end
            end
        end
    else
        for _, obj in pairs(ESPObjects) do
            obj.Box.Visible = false
            obj.Name.Visible = false
            if obj.Highlight then obj.Highlight.Enabled = false end
        end
    end

    -- == Aimbot Target Selection (always find closest) ==
    if AimbotEnabled then
        local closestDist = math.huge
        local closestPlayer = nil
        local mousePos = UserInputService:GetMouseLocation()

        if FOVEnabled then
            FOVCircle.Position = mousePos
            FOVCircle.Radius = FOVRadius
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if EnemyOnly and not IsEnemy(player) then continue end
            local char = GetCharacter(player)
            local root = GetRootPart(char)
            if root and IsAlive(char) then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - mousePos).Magnitude
                    
                    -- Check if inside FOV
                    if FOVEnabled and dist > FOVRadius then
                        continue
                    end

                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end
        AimbotTarget = closestPlayer
    else
        FOVCircle.Visible = false
    end
end)

-- Player/Character tracking
local function OnCharacterAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
        OnCharacterAdded(player)
    else
        OnCharacterAdded(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
        OnCharacterAdded(player)
    else
        OnCharacterAdded(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        if ESPObjects[player].Box then ESPObjects[player].Box:Remove() end
        if ESPObjects[player].Name then ESPObjects[player].Name:Remove() end
        if ESPObjects[player].Highlight then ESPObjects[player].Highlight:Destroy() end
        ESPObjects[player] = nil
    end
end)

-- == Aimbot keybind: press Shift to lock on ==
local AimbotHolding = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Ignoring gameProcessed so it works even if you are sprinting
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        AimbotHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        AimbotHolding = false
    end
end)

-- Aimbot (lock camera/aim only while Shift/RightClick held)
RunService:BindToRenderStep("AshlyAimbot", 201, function()
    if AimbotEnabled and AimbotHolding and AimbotTarget then
        local Camera = workspace.CurrentCamera
        local char = GetCharacter(AimbotTarget)
        local root = GetRootPart(char)
        if root then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                if mousemoverel then
                    local mouseLoc = UserInputService:GetMouseLocation()
                    local diffX = pos.X - mouseLoc.X
                    local diffY = pos.Y - mouseLoc.Y
                    -- Physically moves the mouse cursor so bullets register correctly
                    mousemoverel(diffX / AimbotSmoothness, diffY / AimbotSmoothness)
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
                end
            end
        end
    end
end)

-- == UI: Toggles ==
Tab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        ESPEnabled = Value
        if not Value then
            for _, obj in pairs(ESPObjects) do
                obj.Box.Visible = false
                obj.Name.Visible = false
            end
        end
    end
})

Tab:CreateToggle({
    Name = "Team Check (Hide Teammates)",
    CurrentValue = false,
    Flag = "Team_Check",
    Callback = function(Value)
        EnemyOnly = Value
    end
})

Tab:CreateToggle({
    Name = "Chams (Green Enemy)",
    CurrentValue = false,
    Flag = "Chams_Toggle",
    Callback = function(Value)
        ChamsEnabled = Value
        if not Value then
            for _, obj in pairs(ESPObjects) do
                if obj.Highlight then obj.Highlight.Enabled = false end
            end
        end
    end
})

Tab2:CreateToggle({
    Name = "Aimbot",
    CurrentValue = true,
    Flag = "Aimbot_Toggle",
    Callback = function(Value)
        AimbotEnabled = Value
    end
})

Tab2:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Flag = "FOV_Toggle",
    Callback = function(Value)
        FOVEnabled = Value
    end
})

Tab2:CreateSlider({
    Name = "FOV Size",
    Range = {10, 500},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "FOV_Size",
    Callback = function(Value)
        FOVRadius = Value
    end
})

Tab2:CreateSlider({
    Name = "Aimbot Smoothness (Mouse)",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 4,
    Flag = "Aimbot_Smoothness",
    Callback = function(Value)
        AimbotSmoothness = Value
    end
})

Tab2:CreateSection("Hold Shift to aimbot")
