local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Slime Out Fish | by Nicha",
   LoadingTitle = "Loading Script...",
   LoadingSubtitle = "by Nicha",
   ConfigurationSaving = { Enabled = false }
})

-- สร้าง 5 แท็บ พร้อมใส่ชื่อ Lucide Icons ในวิธีที่ 1
local MainTab = Window:CreateTab("Main", "crosshair")
local CollectTab = Window:CreateTab("Collect", "hand")
local SellTab = Window:CreateTab("Sell Fish", "shopping-bag")
local EspTab = Window:CreateTab("Esp Fish", "eye")
local MiscTab = Window:CreateTab("Misc", "sliders")

-- Services & Variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local WeaponRemote = ReplicatedStorage:WaitForChild("FishGame"):WaitForChild("Remotes"):WaitForChild("WeaponAction")
local UpgradeRemote = ReplicatedStorage:WaitForChild("FishGame"):WaitForChild("Remotes"):WaitForChild("UpgradeAction")
local MerchantRemote = ReplicatedStorage:WaitForChild("FishGame"):WaitForChild("Remotes"):WaitForChild("TravelingMerchantAction")

-- Configurations
local Config = {
    FishName = "Fish",
    PromptName = "",
    TpHeight = 2,
    HoldTime = 0,
    StayTime = 0.1
}

local KillAuraEnabled = false
local KillAuraDistance = 150

local AutoPickupEnabled = false
local AutoTPPickupEnabled = false
local PickupDistance = 13
local PickupSpeed = 0.2

local WalkSpeedValue = 16
local ESPDownedFishEnabled = false
local InfiniteJumpEnabled = false

local AutoSellEnabled = false
local AutoSellInterval = 5

local HumanoidRootPart = nil
local PreAutoTPCFrame = nil
local isFiring = false

-- Function อัปเดต Character/HumanoidRootPart
local function refreshChar()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
    return char
end

-- Function ปรับแต่งฟิสิกส์ตัวละคร
local function setNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
            if state then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end

-- Function วาร์ปกลับจุดเกิด
local function returnToSpawn()
    refreshChar()
    setNoclip(false)
    
    if not HumanoidRootPart then return end
    
    local spawnLoc = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
    if spawnLoc and spawnLoc:IsA("BasePart") then
        HumanoidRootPart.CFrame = spawnLoc.CFrame + Vector3.new(0, 3, 0)
    elseif PreAutoTPCFrame then
        HumanoidRootPart.CFrame = PreAutoTPCFrame
    end
end

-- Function Resolve Part/Position
local function resolvePart(obj)
    if not obj or not obj:IsDescendantOf(Workspace) then return nil end
    
    if obj:IsA("BasePart") then
        return obj
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part
        end
    end
    return nil
end

-- Function ค้นหา ProximityPrompt
local function findPrompt(obj)
    if not obj then return nil end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name:lower():find(Config.PromptName:lower(), 1, true) then 
            return d 
        end
    end
    if obj.Parent then
        for _, d in ipairs(obj.Parent:GetChildren()) do
            if d:IsA("ProximityPrompt") and d.Name:lower():find(Config.PromptName:lower(), 1, true) then 
                return d 
            end
        end
    end
    return nil
end

-- Function ค้นหาปลา
local function findFish()
    local list, seen = {}, {}
    local downedFolder = Workspace:FindFirstChild("DownedFish")
    
    local searchTarget = downedFolder and downedFolder:GetChildren() or Workspace:GetChildren()
    
    for _, obj in ipairs(searchTarget) do
        local objName = obj.Name:lower()
        if not objName:find("cooler") and not objName:find("shop") and not objName:find("store") and not objName:find("dog") then
            local prompt = findPrompt(obj)
            if prompt then
                local part = resolvePart(obj)
                if part and part.Parent and not seen[part] then
                    seen[part] = true
                    table.insert(list, {obj = obj, part = part, prompt = prompt})
                end
            end
        end
    end
    return list
end

-- Function วาร์ปเก็บปลา
local function collectAt(entry)
    local part = entry.part
    if not part or not part.Parent then return false end
    
    refreshChar()
    if not HumanoidRootPart then return false end
    
    setNoclip(true)
    HumanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(0, Config.TpHeight, 0))
    
    pcall(function()
        firetouchinterest(HumanoidRootPart, part, 0)
        task.wait()
        firetouchinterest(HumanoidRootPart, part, 1)
    end)
    
    local prompt = entry.prompt or findPrompt(entry.obj)
    if not prompt or not prompt.Parent then 
        task.wait(0.1)
        return false 
    end
    
    local t0 = tick()
    while tick() - t0 < 0.8 do
        if not HumanoidRootPart or not HumanoidRootPart.Parent then refreshChar() end
        setNoclip(true)
        
        local parent = prompt.Parent
        if not parent then break end
        
        local anchor = parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart")
        if anchor then
            if (HumanoidRootPart.Position - anchor.Position).Magnitude <= (prompt.MaxActivationDistance or 10) then 
                break 
            end
            HumanoidRootPart.CFrame = CFrame.new(anchor.Position + Vector3.new(0, Config.TpHeight, 0))
        end
        task.wait(0.05)
    end
    
    pcall(function() fireproximityprompt(prompt, Config.HoldTime) end)
    task.wait(Config.StayTime)
    pcall(function() fireproximityprompt(prompt) end)
    
    task.wait(0.05)
    return true
end

-- Function ขายปลา
local function sellFish()
    pcall(function()
        UpgradeRemote:FireServer("SellFish")
    end)
end

-- Function สร้าง Highlight
local function applyHighlight(fish)
    if not fish or not fish:IsDescendantOf(Workspace) then return end
    if fish:FindFirstChild("DownedFishHighlight") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "DownedFishHighlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 127)
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = fish
    highlight.Parent = fish
end

-- Function ลบ Highlight
local function removeHighlight(fish)
    if fish and fish:FindFirstChild("DownedFishHighlight") then
        fish.DownedFishHighlight:Destroy()
    end
end

-- Function ยิงอาวุธ
local function fireWeaponDirectToTarget(targetPart, targetObj)
    refreshChar()
    if not HumanoidRootPart or not targetPart then return end
    
    local targetPosition = targetPart.Position
    local origin = HumanoidRootPart.Position
    local trueDirection = (targetPosition - origin).Unit
    
    local candidate = {}
    if targetObj then
        table.insert(candidate, targetObj)
    end

    WeaponRemote:FireServer(
        "Fire",
        {
            direction = trueDirection,
            origin = origin,
            target = targetPosition,
            shotTime = tick(),
            candidateFish = candidate
        }
    )
end

-- Function ยิงเป้าหมายทั้งหมดในระยะ (Kill Aura)
local function shootAllTargetsInRange()
    if isFiring then return end
    isFiring = true
    
    refreshChar()
    if HumanoidRootPart then
        local originPos = HumanoidRootPart.Position
        local targets = {}

        -- 1. เช็ค ActiveBoss
        local activeBoss = Workspace:FindFirstChild("ActiveBoss")
        if activeBoss then
            local bossPart = resolvePart(activeBoss)
            if bossPart then
                local dist = (originPos - bossPart.Position).Magnitude
                if dist <= KillAuraDistance then
                    table.insert(targets, {part = bossPart, obj = activeBoss, dist = dist})
                end
            else
                for _, child in ipairs(activeBoss:GetChildren()) do
                    local part = resolvePart(child)
                    if part then
                        local dist = (originPos - part.Position).Magnitude
                        if dist <= KillAuraDistance then
                            table.insert(targets, {part = part, obj = child, dist = dist})
                        end
                    end
                end
            end
        end

        -- 2. เช็คปลาใน ActiveFish
        local activeFishFolder = Workspace:FindFirstChild("ActiveFish")
        if activeFishFolder then
            for _, fish in ipairs(activeFishFolder:GetChildren()) do
                local part = resolvePart(fish)
                if part then
                    local dist = (originPos - part.Position).Magnitude
                    if dist <= KillAuraDistance then
                        table.insert(targets, {part = part, obj = fish, dist = dist})
                    end
                end
            end
        end

        table.sort(targets, function(a, b) return a.dist < b.dist end)

        for _, targetData in ipairs(targets) do
            fireWeaponDirectToTarget(targetData.part, targetData.obj)
        end
    end

    task.wait(0.03)
    isFiring = false
end

-- Function เปิด Shop
local function openShop()
    pcall(function()
        local cooler = Workspace:FindFirstChild("FishCooler")
        if cooler and cooler:FindFirstChild("Main") then
            local prompt = cooler.Main:FindFirstChildOfClass("ProximityPrompt") or cooler.Main:FindFirstChild("ProximityPrompt")
            if prompt then
                fireproximityprompt(prompt)
            end
        end
    end)
end

-- Function เปิดพ่อค้าเดินทาง (Traveling Merchant)
local function openMerchant()
    pcall(function()
        MerchantRemote:InvokeServer("Open", nil)
    end)
end

-- ==========================================
-- 1. แท็บ Main
-- ==========================================
MainTab:CreateToggle({
   Name = "Kill Aura (ยิงให้อัตโนมัติ)",
   CurrentValue = false,
   Callback = function(Value)
      KillAuraEnabled = Value
   end,
})

MainTab:CreateSlider({
   Name = "Kill Aura Distance",
   Range = {10, 500},
   Increment = 10,
   Suffix = " Studs",
   CurrentValue = 150,
   Callback = function(Value)
      KillAuraDistance = Value
   end,
})

-- ==========================================
-- 2. แท็บ Collect
-- ==========================================
CollectTab:CreateToggle({
   Name = "Auto Pickup TP (วาร์ปเก็บปลา)",
   CurrentValue = false,
   Callback = function(Value)
      AutoTPPickupEnabled = Value
      if Value then
          refreshChar()
          if HumanoidRootPart then
              PreAutoTPCFrame = HumanoidRootPart.CFrame
          end
      else
          returnToSpawn()
      end
   end,
})

CollectTab:CreateSlider({
   Name = "TP Height (ความสูงวาร์ปเหนือปลา)",
   Range = {0, 10},
   Increment = 1,
   Suffix = " Studs",
   CurrentValue = 2,
   Callback = function(Value)
      Config.TpHeight = Value
   end,
})

CollectTab:CreateSlider({
   Name = "Stay Time (เวลาค้างกดเก็บ)",
   Range = {0.05, 1},
   Increment = 0.05,
   Suffix = "s",
   CurrentValue = 0.1,
   Callback = function(Value)
      Config.StayTime = Value
   end,
})

CollectTab:CreateToggle({
   Name = "Auto Pickup (Normal Range)",
   CurrentValue = false,
   Callback = function(Value)
      AutoPickupEnabled = Value
   end,
})

CollectTab:CreateSlider({
   Name = "Pickup Distance",
   Range = {1, 30},
   Increment = 1,
   Suffix = " Studs",
   CurrentValue = 13,
   Callback = function(Value)
      PickupDistance = Value
   end,
})

-- ==========================================
-- 3. แท็บ Sell Fish
-- ==========================================
SellTab:CreateButton({
   Name = "Open Traveling Merchant (เปิดร้านพ่อค้าเดินทาง)",
   Callback = function()
      openMerchant()
      Rayfield:Notify({Title = "Merchant UI", Content = "เปิด UI พ่อค้าเดินทางแล้ว!", Duration = 3})
   end,
})

SellTab:CreateButton({
   Name = "Sell Fish (ขายปลาทันที)",
   Callback = function()
      sellFish()
      Rayfield:Notify({Title = "Sell Fish", Content = "ส่งคำสั่งขายปลาเรียบร้อยแล้ว!", Duration = 3})
   end,
})

SellTab:CreateToggle({
   Name = "Auto Sell Fish",
   CurrentValue = false,
   Callback = function(Value)
      AutoSellEnabled = Value
   end,
})

SellTab:CreateSlider({
   Name = "Auto Sell Interval (ระยะเวลาขาย)",
   Range = {1, 60},
   Increment = 1,
   Suffix = "s",
   CurrentValue = 5,
   Callback = function(Value)
      AutoSellInterval = Value
   end,
})

SellTab:CreateButton({
   Name = "Open Shop (เปิดร้านค้าทั่วไป)",
   Callback = function()
      openShop()
   end,
})

-- ==========================================
-- 4. แท็บ Esp Fish
-- ==========================================
EspTab:CreateToggle({
   Name = "ESP Highlight DownedFish",
   CurrentValue = false,
   Callback = function(Value)
      ESPDownedFishEnabled = Value
      local downedFishFolder = Workspace:FindFirstChild("DownedFish")
      
      if downedFishFolder then
          if Value then
              for _, fish in ipairs(downedFishFolder:GetChildren()) do
                  applyHighlight(fish)
              end
          else
              for _, fish in ipairs(downedFishFolder:GetChildren()) do
                  removeHighlight(fish)
              end
          end
      end
   end,
})

-- ==========================================
-- 5. แท็บ Misc
-- ==========================================
MiscTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 200},
   Increment = 1,
   Suffix = " Speed",
   CurrentValue = 16,
   Callback = function(Value)
      WalkSpeedValue = Value
      local character = LocalPlayer.Character
      if character and character:FindFirstChild("Humanoid") then
          character.Humanoid.WalkSpeed = Value
      end
   end,
})

MiscTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Callback = function(Value)
      InfiniteJumpEnabled = Value
   end,
})

-- ==========================================
-- System Event Connections & Loops
-- ==========================================

-- Event สำหรับ Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChildOfClass("Humanoid") then
            character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Loop สำหรับ Auto Sell Fish
task.spawn(function()
    while true do
        if AutoSellEnabled then
            sellFish()
            task.wait(AutoSellInterval)
        else
            task.wait(1)
        end
    end
end)

-- Loop อัปเดต WalkSpeed
task.spawn(function()
    while task.wait(0.1) do
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            if character.Humanoid.WalkSpeed ~= WalkSpeedValue then
                character.Humanoid.WalkSpeed = WalkSpeedValue
            end
        end
    end
end)

-- Loop ESP DownedFish
task.spawn(function()
    local downedFishFolder = Workspace:WaitForChild("DownedFish", 5)
    if downedFishFolder then
        downedFishFolder.ChildAdded:Connect(function(fish)
            if ESPDownedFishEnabled then
                task.wait(0.1)
                applyHighlight(fish)
            end
        end)
    end
end)

-- Loop Auto Kill Aura (ยิงให้อัตโนมัติ)
task.spawn(function()
    while task.wait(0.08) do
        if KillAuraEnabled then
            shootAllTargetsInRange()
        end
    end
end)

-- Loop Auto Pickup TP
task.spawn(function()
    local wasPickingUp = false
    while true do
        if AutoTPPickupEnabled then
            local fishList = findFish()
            if #fishList > 0 then
                wasPickingUp = true
                for _, entry in ipairs(fishList) do
                    if not AutoTPPickupEnabled then break end
                    collectAt(entry)
                end
            else
                if wasPickingUp then
                    returnToSpawn()
                    wasPickingUp = false
                end
                task.wait(0.3)
            end
        else
            if wasPickingUp then
                returnToSpawn()
                wasPickingUp = false
            end
            task.wait(0.5)
        end
    end
end)

-- Loop Auto Pickup
task.spawn(function()
    while true do
        if AutoPickupEnabled and not AutoTPPickupEnabled then
            refreshChar()
            local downedFishFolder = Workspace:FindFirstChild("DownedFish")

            if HumanoidRootPart and downedFishFolder then
                for _, fish in ipairs(downedFishFolder:GetChildren()) do
                    if not AutoPickupEnabled or AutoTPPickupEnabled then break end
                    
                    if fish and fish:IsDescendantOf(Workspace) then
                        local fishPart = resolvePart(fish)
                        
                        if fishPart then
                            local distance = (HumanoidRootPart.Position - fishPart.Position).Magnitude
                            
                            if distance <= PickupDistance then
                                local prompt = findPrompt(fish)
                                if prompt then
                                    prompt.RequiresLineOfSight = false
                                    prompt.HoldDuration = 0
                                    fireproximityprompt(prompt)
                                end
                                task.wait(PickupSpeed)
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)
