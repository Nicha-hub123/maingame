-- โหลด Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- สร้าง Window
local Window = Rayfield:CreateWindow({
   Name = "Auto Queue System (Fixed)",
   LoadingTitle = "กำลังโหลดสคริปต์...",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- สร้าง Tab
local MainTab = Window:CreateTab("Main Queue", 4483362458)

-- ตัวแปรสถานะ
local autoQueueEnabled = false
local partySize = 1

-- สร้าง Dropdown เลือกระดับ Party (1-4)
MainTab:CreateDropdown({
   Name = "เลือกขนาด Party (1-4)",
   Options = {"1", "2", "3", "4"},
   CurrentOption = {"1"},
   MultipleOptions = false,
   Flag = "PartySizeDropdown",
   Callback = function(Option)
      partySize = tonumber(Option[1])
   end,
})

-- สร้าง Toggle สำหรับ เปิด/ปิด Auto Queue
MainTab:CreateToggle({
   Name = "เปิดใช้งาน Auto Queue & Teleport",
   CurrentValue = false,
   Flag = "AutoQueueToggle",
   Callback = function(Value)
      autoQueueEnabled = Value
   end,
})

-- ฟังก์ชันสำหรับตรวจสอบโซนที่ว่าง (ปรับปรุงระบบอ่านค่า Text)
local function findAvailableZone()
   local teleportZones = workspace:FindFirstChild("TeleportZones")
   if not teleportZones then 
      warn("[Auto Queue] ไม่พบ folder TeleportZones ใน Workspace")
      return nil 
   end

   local zoneNames = {"TeleportZone1", "TeleportZone2", "TeleportZone3"}

   for _, name in ipairs(zoneNames) do
      local zone = teleportZones:FindFirstChild(name)
      if zone then
         local success, err = pcall(function()
            local countLabel = zone.Border.BillBoardHolder.BillboardGui.PlayerCount
            local text = tostring(countLabel.Text)
            
            -- ตัดช่องว่างหน้าหลังออก
            text = text:match("^%s*(.-)%s*$")
            
            -- พิมพ์เช็คใน F12 (Console) เพื่อดูว่าเกมส่งค่าอะไรมา
            -- print("[Auto Queue Debug] " .. name .. " Text: '" .. text .. "'")

            -- เช็คเงื่อนไข: มีเลข 0 อยู่นำหน้า หรือมีข้อความว่าง/0/X
            if text:find("^0") or text == "0" or text:find("0/") then
               return zone
            end
         end)
         
         if success and err then
            return err -- ส่งค่า zone กลับถ้าเจอ
         end
      end
   end
   return nil
end

-- ฟังก์ชันสำหรับวาร์ปตัวละครไปยังโซน (ปรับปรุงให้รองรับทั้ง Part และ Model)
local function teleportToZone(zone)
   local player = game.Players.LocalPlayer
   if not (player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
      return
   end

   local targetCFrame = nil

   -- ดึง CFrame จาก Part หรือ Model
   if zone:IsA("BasePart") then
      targetCFrame = zone.CFrame
   elseif zone:IsA("Model") then
      targetCFrame = zone:GetPivot()
   elseif zone:FindFirstChild("Border") and zone.Border:IsA("BasePart") then
      targetCFrame = zone.Border.CFrame
   end

   if targetCFrame then
      player.Character.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
   end
end

-- Loop การทำงานของ Auto Queue
task.spawn(function()
   while task.wait(1) do
      if autoQueueEnabled then
         local availableZone = findAvailableZone()
         
         if availableZone then
            -- วาร์ปไปที่โซนนั้น
            teleportToZone(availableZone)
            task.wait(0.3)
            
            -- ยิง Remote Event ตั้งค่า Party Size
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("LobbyRemotes")
               and game:GetService("ReplicatedStorage").LobbyRemotes:FindFirstChild("SetPartySize")
            
            if remote then
               remote:FireServer(partySize)
            end
         end
      end
   end
end)
