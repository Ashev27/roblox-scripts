local AshlyState = getgenv().AshlyState
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPObjects = {}

local function GetCharacter(player)
    if not player then return nil end
    local char = player.Character
    if char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("Humanoid")) then return char end
    local wsChar = workspace:FindFirstChild(player.Name)
    if wsChar and wsChar:IsA("Model") and (wsChar:FindFirstChild("HumanoidRootPart") or wsChar:FindFirstChildOfClass("Humanoid")) then return wsChar end
    return nil
end

local function GetRootPart(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function GetHumanoid(char)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(char)
    if not char then return false end
    local hum = GetHumanoid(char)
    if hum then return hum.Health > 0 end
    return GetRootPart(char) ~= nil
end

local function IsEnemy(player)
    if not player or not LocalPlayer then return false end
    if LocalPlayer.Neutral or player.Neutral then return true end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then return LocalPlayer.Team ~= player.Team end
    return true
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
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
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Enabled = false
    
    pcall(function() highlight.Parent = game:GetService("CoreGui") end)
    if not highlight.Parent then highlight.Parent = workspace end

    ESPObjects[player] = {Box = box, Name = nameText, Highlight = highlight}
end

RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    if AshlyState.ESPEnabled or AshlyState.ChamsEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local isEnemy = IsEnemy(player)
            
            if AshlyState.EnemyOnly and not isEnemy then
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
                if AshlyState.ChamsEnabled and obj.Highlight then
                    if obj.Highlight.Adornee ~= char then obj.Highlight.Adornee = char end
                    obj.Highlight.Enabled = true
                    if isEnemy then
                        obj.Highlight.FillColor = Color3.fromRGB(0, 255, 0)
                        obj.Highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                    else
                        obj.Highlight.FillColor = Color3.fromRGB(0, 255, 255)
                        obj.Highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
                    end
                else
                    if obj.Highlight then obj.Highlight.Enabled = false end
                end

                if AshlyState.ESPEnabled then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local size = Vector2.new(4000 / pos.Z, 6000 / pos.Z)
                        obj.Box.Size = size
                        obj.Box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                        
                        local color = isEnemy and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 255, 255)
                        obj.Box.Color = color
                        obj.Name.Color = color
                        
                        obj.Box.Visible = true
                        obj.Name.Text = player.Name
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
end)

local function OnCharacterAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if player ~= LocalPlayer then CreateESP(player) end
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
    OnCharacterAdded(player)
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then CreateESP(player) end
    OnCharacterAdded(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        if ESPObjects[player].Box then ESPObjects[player].Box:Remove() end
        if ESPObjects[player].Name then ESPObjects[player].Name:Remove() end
        if ESPObjects[player].Highlight then ESPObjects[player].Highlight:Destroy() end
        ESPObjects[player] = nil
    end
end)
