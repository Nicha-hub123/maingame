-- ดึง PlaceId ของเกมที่ผู้เล่นกำลังเล่นอยู่
local placeId = game.PlaceId

-- ตารางรวมลิงก์สคริปต์แยกตาม PlaceId ของแต่ละเกม
local scripts = {
    -- [PlaceId ของเกม] = "ลิงก์ Raw สคริปต์ของเกมนั้น"
    [113945994875620] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Slimeoutfish.lua",
    [1234567890] = "https://raw.githubusercontent.com/USER/REPO/main/fishgame.lua",   -- ตัวอย่าง: Fish Game
    [9876543210] = "https://raw.githubusercontent.com/USER/REPO/main/kinglegacy.lua", -- ตัวอย่าง: King Legacy
}

-- ตรวจสอบว่า PlaceId ปัจจุบันตรงกับในตารางหรือไม่
if scripts[placeId] then
    -- ถ้าเจอ ให้สั่งโหลดสคริปต์ของแมพนั้นมารัน
    loadstring(game:HttpGet(scripts[placeId]))()
else
    -- ถ้าไม่เจอแมพที่รองรับ ให้แจ้งเตือนผู้ใช้
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Script Hub",
        Text = "เกมนี้ยังไม่รองรับ! (Place ID: " .. tostring(placeId) .. ")",
        Duration = 5
    })
end
