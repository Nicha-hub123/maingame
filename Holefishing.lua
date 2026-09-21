-- โหลด Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Hole Fishing | by Nicha",
   LoadingTitle = "Loading Hole Fishing Script...",
   LoadingSubtitle = "by Nicha",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("Auto Fishing", 4483362458)
local SellTab = Window:CreateTab("Sell System", 4483362458)
local UpgradeTab = Window:CreateTab("Upgrade System", 4483362458)

local AutoFishToggle = false
local ChargeTime = 1.15 -- ค่าเริ่มต้น 1.15 วินาที

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SellHeldFishFunction = Remotes:WaitForChild("SellHeldFish")
local SellInventoryFunction = Remotes:WaitForChild("SellInventory")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local FishingUI = PlayerGui:WaitForChild("FishingUI")
local CatchUI = FishingUI:WaitForChild("Catch")

-- ฟังก์ชันสัมผัสหน้าจอ
local function touchDown()
    local x = Workspace.CurrentCamera.ViewportSize.X / 2
    local y = Workspace.CurrentCamera.ViewportSize.Y / 2
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
end

local function touchUp()
    local x = Workspace.CurrentCamera.ViewportSize.X / 2
    local y = Workspace.CurrentCamera.ViewportSize.Y / 2
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

local function isCatchUIActive()
    if not CatchUI then return false end
    local isVisible = CatchUI.Visible
    local isEnabled = true
    if CatchUI:IsA("ScreenGui") then isEnabled = CatchUI.Enabled end
    local inScreen = CatchUI.AbsolutePosition.Y >= 0 and CatchUI.AbsoluteSize.Y > 0
    local isTransparent = false
    if CatchUI:IsA("CanvasGroup") then
        isTransparent = (CatchUI.GroupTransparency >= 0.9)
    end
    return isVisible and isEnabled and inScreen and not isTransparent
end

-- ==========================================
-- 🎣 ระบบ AUTO FISHING
-- ==========================================
local function startReliableFishing()
    task.spawn(function()
        while AutoFishToggle do
            local character = LocalPlayer.Character
            local tool = character and character:FindFirstChildOfClass("Tool")
            
            if tool then
                touchDown()
                task.wait(ChargeTime)
                touchUp()
                
                local timer = 0
                while AutoFishToggle and not isCatchUIActive() do
                    task.wait(0.1)
                    timer = timer + 0.1
                    if timer >= 10 then break end
                end
                
                if isCatchUIActive() then
                    touchDown()
                    while AutoFishToggle and isCatchUIActive() do
                        task.wait(0.05)
                    end
                    touchUp()
                end
                
                task.wait(1.2)
            else
                Rayfield:Notify({
                   Title = "⚠️Warning⚠️",
                   Content = "กรุณากดถือเบ็ดตกปลาก่อนเปิดใช้งาน !!!",
                   Duration = 2,
                })
                task.wait(3)
            end
        end
    end)
end

MainTab:CreateToggle({
   Name = "Auto Fish (Fix Catch Detect)",
   CurrentValue = false,
   Flag = "FixCatchAutoFish",
   Callback = function(Value)
      AutoFishToggle = Value
      if Value then
          Rayfield:Notify({
             Title = "Started",
             Content = "เริ่มระบบตกปลาอัตโนมัติแล้ว",
             Duration = 2,
          })
          startReliableFishing()
      else
          touchUp()
          Rayfield:Notify({
             Title = "Stopped",
             Content = "ปิดระบบตกปลาเรียบร้อยแล้ว",
             Duration = 2,
          })
      end
   end,
})

MainTab:CreateSlider({
   Name = "เวลากดค้างชาร์จ Perfect (เหวี่ยงเบ็ด)",
   Range = {0.5, 3.0},
   Increment = 0.05,
   Suffix = "s",
   CurrentValue = 1.15,
   Flag = "ChargeTimeSliderFix",
   Callback = function(Value)
      ChargeTime = Value
   end,
})

-- ==========================================
-- 💰 ระบบขายปลา (TP SELL & RETURN)
-- ==========================================
local function tpSellAndReturn(sellType)
    task.spawn(function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        local sellerObj = workspace:FindFirstChild("MAP") 
            and workspace.MAP:FindFirstChild("Envrionment") 
            and workspace.MAP.Envrionment:FindFirstChild("Sell") 
            and workspace.MAP.Envrionment.Sell:FindFirstChild("Seller")

        if hrp and sellerObj then
            local originalCFrame = hrp.CFrame
            local sellerCFrame = sellerObj:IsA("Model") and sellerObj:GetPrimaryPartCFrame() or sellerObj.CFrame
            
            if not sellerCFrame then
                local anyPart = sellerObj:FindFirstChildOfClass("BasePart", true)
                if anyPart then sellerCFrame = anyPart.CFrame end
            end

            if sellerCFrame then
                hrp.CFrame = sellerCFrame * CFrame.new(0, 0, -3)
                task.wait(0.2)
                
                for _, prompt in ipairs(sellerObj:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        fireproximityprompt(prompt)
                    end
                end
                
                task.wait(0.2)
                
                local res = nil
                if sellType == "Hand" then
                    pcall(function() res = SellHeldFishFunction:InvokeServer() end)
                elseif sellType == "All" then
                    pcall(function() res = SellInventoryFunction:InvokeServer() end)
                end
                
                task.wait(0.2)
                hrp.CFrame = originalCFrame
                
                if res and type(res) == "table" and res.sold then
                    local totalVal = res.value or 0
                    local countText = res.count and (" " .. tostring(res.count) .. " ตัว") or ""
                    Rayfield:Notify({
                       Title = "Sell Success!",
                       Content = "ขายปลาสำเร็จ" .. countText .. " ได้รับ: $" .. tostring(totalVal),
                       Duration = 3,
                    })
                else
                    Rayfield:Notify({
                       Title = "Sell Complete",
                       Content = "ทำรายการขายปลาเรียบร้อยแล้ว",
                       Duration = 2,
                    })
                end
            end
        end
    end)
end

SellTab:CreateButton({
   Name = "Sell Hand (วาร์ปขายปลาในมือ -> กลับจุดเดิม)",
   Callback = function()
       tpSellAndReturn("Hand")
   end,
})

SellTab:CreateButton({
   Name = "Sell All (วาร์ปขายปลาทั้งหมด -> กลับจุดเดิม)",
   Callback = function()
       tpSellAndReturn("All")
   end,
})

-- ==========================================
-- 🛠️ ระบบ TP ไปเปิด UPGRADE UI (`workspace.Market.Upgrades.zone`)
-- ==========================================

local function tpOpenUpgradeZone()
    task.spawn(function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        -- ระบุตำแหน่งโซนตามที่คุณแจ้ง: workspace.Market.Upgrades.zone
        local upgradeZone = workspace:FindFirstChild("Market") 
            and workspace.Market:FindFirstChild("Upgrades") 
            and workspace.Market.Upgrades:FindFirstChild("zone")

        if hrp and upgradeZone then
            -- 1. บันทึกพิกัดตำแหน่งยืนปัจจุบันไว้
            local originalCFrame = hrp.CFrame
            
            -- หา CFrame ของ Zone Part
            local zoneCFrame = upgradeZone:IsA("BasePart") and upgradeZone.CFrame or (upgradeZone:IsA("Model") and upgradeZone:GetPrimaryPartCFrame())
            if not zoneCFrame then
                local anyPart = upgradeZone:FindFirstChildOfClass("BasePart", true)
                if anyPart then zoneCFrame = anyPart.CFrame end
            end

            if zoneCFrame then
                -- 2. วาร์ปตัวละครเข้าไปเหยียบกลางโซน Upgrade เพื่อกระตุ้นระบบเปิด UI ของเกม
                hrp.CFrame = zoneCFrame
                task.wait(0.3) -- รอระบบเซิร์ฟเวอร์เปิดหน้าต่าง UI
                
                -- 3. วาร์ปตัวละครกลับมาตำแหน่งตกปลาเดิมทันที (หน้าต่าง Upgrade UI จะยังคงค้างเปิดอยู่บนหน้าจอ)
                hrp.CFrame = originalCFrame
                
                Rayfield:Notify({
                   Title = "Upgrade UI Opened",
                   Content = "วาร์ปไปเปิดหน้าต่างอัปเกรดและกลับจุดเดิมเรียบร้อยแล้ว",
                   Duration = 2.5,
                })
            end
        else
            Rayfield:Notify({
               Title = "Error",
               Content = "ไม่พบจุด workspace.Market.Upgrades.zone",
               Duration = 2,
            })
        end
    end)
end

UpgradeTab:CreateButton({
   Name = "Open Upgrade UI (วาร์ปไปเปิดร้าน -> กลับจุดเดิม)",
   Callback = function()
       tpOpenUpgradeZone()
   end,
})
