local AshlyState = getgenv().AshlyState
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false
FOVCircle.Radius = 100 

local AimbotTarget = nil
local AimbotHolding = false

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

local function IsEnemy(player)
    if not player or not LocalPlayer then return false end
    if LocalPlayer.Neutral or player.Neutral then return true end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then return LocalPlayer.Team ~= player.Team end
    return true
end

RunService.RenderStepped:Connect(function()
    local Camera = workspace.CurrentCamera
    if AshlyState.AimbotEnabled then
        local closestDist = math.huge
        local closestPlayer = nil
        local mousePos = UserInputService:GetMouseLocation()

        if AshlyState.FOVEnabled then
            FOVCircle.Position = mousePos
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if AshlyState.EnemyOnly and not IsEnemy(player) then continue end
            local char = GetCharacter(player)
            local root = GetRootPart(char)
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - mousePos).Magnitude
                    
                    if AshlyState.FOVEnabled and dist > FOVCircle.Radius then
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
        AimbotTarget = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        AimbotHolding = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        AimbotHolding = false
    end
end)

-- Step 4: Make logic dependent on runtime (Randomized smoothing against static analysis / basic anti-cheats)
local function getSmoothness()
    -- Dynamic smoothing between (Smoothness - 0.2) and (Smoothness + 0.2)
    return AshlyState.AimbotSmoothness + (math.random(-2, 2) / 10)
end

RunService:BindToRenderStep("AshlyAimbot", 201, function()
    if AshlyState.AimbotEnabled and AimbotHolding and AimbotTarget then
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
                    local smooth = getSmoothness()
                    mousemoverel(diffX / smooth, diffY / smooth)
                else
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)
                end
            end
        end
    end
end)
