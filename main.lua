local placeId = game.PlaceId
local scripts = {
    [115942182868656] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Slimeoutfish.lua",
    [98502499119821] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Heavyweightfishing.lua",   
    [80158232099900] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Holefishing.lua", 
    [113945994875620] = "https://raw.githubusercontent.com/Nicha-hub123/maingame/refs/heads/main/Slimeoutfish.lua",
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
