local Window = getgenv().AshlyWindow
local AshlyState = getgenv().AshlyState

local Tab = Window:CreateTab("Main", 4483362458)

Tab:CreateButton({
   Name = "Join Our Discord",
   Callback = function()
      setclipboard("https://discord.gg/uevZf2qtM")
      getgenv().AshlyRayfield:Notify({
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
Tab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(Value)
        AshlyState.ESPEnabled = Value
    end
})

Tab:CreateToggle({
    Name = "Team Check (Hide Teammates)",
    CurrentValue = false,
    Flag = "Team_Check",
    Callback = function(Value)
        AshlyState.EnemyOnly = Value
    end
})

Tab:CreateToggle({
    Name = "Chams (Green - Visible Only)",
    CurrentValue = false,
    Flag = "Chams_Toggle",
    Callback = function(Value)
        AshlyState.ChamsEnabled = Value
    end
})

local Tab2 = Window:CreateTab("Aimbot", 4483362458)
Tab2:CreateSection("Aimbot")
Tab2:CreateToggle({
    Name = "Aimbot",
    CurrentValue = true,
    Flag = "Aimbot_Toggle",
    Callback = function(Value)
        AshlyState.AimbotEnabled = Value
    end
})

Tab2:CreateToggle({
    Name = "Show FOV Circle (Fixed 100px)",
    CurrentValue = false,
    Flag = "FOV_Toggle",
    Callback = function(Value)
        AshlyState.FOVEnabled = Value
    end
})

Tab2:CreateSection("Hold Shift to aimbot (Torso only)")
