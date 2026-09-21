local placeId = game.PlaceId
local scripts = {
    [113945994875620] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Slimeoutfish.lua",
    [98502499119821] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Heavyweightfishing.lua",   
    [9876543210] = "https://raw.githubusercontent.com/USER/REPO/main/kinglegacy.lua", 
}

if scripts[placeId] then
    loadstring(game:HttpGet(scripts[placeId]))()
else
   game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Script Hub",
        Text = "เกมนี้ยังไม่รองรับ! (Place ID: " .. tostring(placeId) .. ")",
        Duration = 5
    })
end
