local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage.Remotes

local CurrencyService = {} -- เก็บเป็น Table

local playerCurrency: { [Player]: number } = {}

local startingCurrency = 200 -- เงินเริ่มต้น Edit ได้

function CurrencyService.getCurrency(player: Player): number -- Function ในการส่ง ค่าเงิน ของ Player นั้นๆกลับไปหาผู้ส่ง
    return playerCurrency[player] or 0
end

function CurrencyService.addCurrency(player: Player, amount: number) -- Function การเพิ่มเงินให้แก้ Player
    playerCurrency[player] = (playerCurrency[player] or 0) + amount -- + amount ที่กำหนดให้แก้ Player
    Remotes.UpdateCurrency:FireClient(player, playerCurrency[player]) -- Fire ค่าใน player และ playerCurrency ไปยัง Client
end

function CurrencyService.deductCurrency(player: Player, amount: number): boolean -- Function ในการหักเงินผู้เล่น
    local current = playerCurrency[player] or 0
    if current < amount then
        return false -- กรณี้นี้คือ เงินที่มี(current) น้อยกว่า amount(ราคา) หรือก็คือไม่มีปัญญาจ่าย
    end

    playerCurrency[player] = current - amount -- กรณีที่เงินพอก็ให้เอา current ไปหักกับ amount
    Remotes.UpdateCurrency:FireClient(player, playerCurrency[player])

    return true
end

function CurrencyService.initPlayer(player: Player)
    playerCurrency[player] = startingCurrency
    player.CharacterAdded:Wait()
    task.wait(1)
    Remotes.UpdateCurrency:FireClient(player, playerCurrency[player])
end

function CurrencyService.cleanupPlayer(player: Player)
    playerCurrency[player] = nil
end

return CurrencyService