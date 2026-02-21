local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UpdateBase = Remotes:WaitForChild("UpdateBase")
local GameOver = Remotes:WaitForChild("GameOver")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("ScreenGui")
local hpDisplay = screenGui:WaitForChild("BaseHP"):WaitForChild("HPDisplay")

UpdateBase.OnClientEvent:Connect(function(currentHP: number, maxHP: number)
    hpDisplay.Text = tostring(currentHP) .. " / " .. tostring(maxHP)
end)

GameOver.OnClientEvent:Connect(function()
    hpDisplay.Text = "GAME OVER"
    hpDisplay.TextColor3 = Color3.fromRGB(255, 50, 50)
end)