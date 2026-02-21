local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyService = require(script.Parent.CurrencyService)
local WaveService = require(script.Parent.WaveService)
local BaseService = require(script.Parent.BaseService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartWave = Remotes:WaitForChild("StartWave")
local UpdateBase = Remotes:WaitForChild("UpdateBase")

Players.PlayerAdded:Connect(function(player)
    CurrencyService.initPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    CurrencyService.cleanupPlayer(player)
end)

local waveStarted = false

StartWave.OnServerEvent:Connect(function(player)
    if waveStarted then return end -- ถ้าเริ่มไปแล้วไม่ทำอะไร
    waveStarted = true
    WaveService.startWave()
end)