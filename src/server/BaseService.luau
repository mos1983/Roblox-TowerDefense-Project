local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateBase = Remotes:WaitForChild("UpdateBase")
local CameraShake = Remotes:WaitForChild("CameraShake")

local BaseService = {}

local maxHP = 200
local currentHP = maxHP

local basePart = workspace:WaitForChild("GameMapTemplat1"):WaitForChild("BasePart")

function BaseService.getHP(): number -- Function สำหรับการส่งค่า HP ปัจจุบันของ Base ให้ ผู้ส่งคำขอ
    return currentHP
end

function BaseService.takeDamage(amount: number)
    currentHP = math.max(0, currentHP - amount)

    UpdateBase:FireAllClients(currentHP, maxHP)
    CameraShake:FireAllClients(amount)
    print(`[Base] HP: {currentHP}/{maxHP}`)

    if currentHP <= 0 then
        BaseService.gameOver()
    end
end

function BaseService.gameOver()
    print("[Base] Game Over!")
    
    local GameOver = Remotes:WaitForChild("GameOver")
    GameOver:FireAllClients()
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Wait()
    task.wait(3)
    UpdateBase:FireClient(player, currentHP, maxHP)
end)

return BaseService