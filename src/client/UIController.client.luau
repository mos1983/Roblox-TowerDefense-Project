local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerConfig = require(ReplicatedStorage.Shared.TowerConfig)
local SlotConfig = require(ReplicatedStorage.Shared.SlotConfig)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartWave = Remotes:WaitForChild("StartWave")
local WaveStarted = Remotes:WaitForChild("WaveStarted")
local WaveCompleted = Remotes:WaitForChild("WaveCompleted")
local UpdateCountdown = Remotes:WaitForChild("UpdateCountdown")

local screenGui = player.PlayerGui:WaitForChild("ScreenGui")
local waveDisplay = screenGui:WaitForChild("Wave"):WaitForChild("WaveDisplay")
local countDisplay = screenGui:WaitForChild("Countdown"):WaitForChild("CountDisplay")
local hotbar = screenGui:WaitForChild("Hotbar")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local currentCurrency = 0

local gameGui = playerGui:WaitForChild("ScreenGui")
local Frame = gameGui:WaitForChild("CurrencyTabs")
local currencyLabel = Frame:WaitForChild("CurrencyB")

-- ตั้งค่าเริ่มต้น
waveDisplay.Text = "Click Here To Start"
waveDisplay.TextColor3 = Color3.fromRGB(50, 255, 50) -- เขียว
countDisplay.Text = ""

local waveStarted = false

-- คลิก WaveDisplay เพื่อเริ่ม Wave
waveDisplay.MouseButton1Click:Connect(function()
    if waveStarted then return end
    StartWave:FireServer()
end)

-- Wave เริ่ม
WaveStarted.OnClientEvent:Connect(function(wave: number)
    waveDisplay.Text = "Wave " .. wave
    waveDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

-- Wave จบ → รอ Wave ถัดไป
WaveCompleted.OnClientEvent:Connect(function(wave: number, reward: number)
    waveStarted = false
end)

-- Countdown
UpdateCountdown.OnClientEvent:Connect(function(seconds: number, isShort: boolean)
    if seconds <= 0 then
        countDisplay.Text = ""
        return
    end

    countDisplay.Text = seconds .. "s"

    if seconds <= 5 then
        countDisplay.TextColor3 = Color3.fromRGB(255, 50, 50) -- แดง
    else
        countDisplay.TextColor3 = Color3.fromRGB(255, 255, 255) -- ขาว
    end
end)

local function updateCostColors()
    for i = 1, 5 do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if not slot then continue end

        local towerName = SlotConfig[i]
        if not towerName then continue end

        local config = TowerConfig[towerName]
        if not config then continue end

        local costLabel = slot:FindFirstChild("ImageButton"):FindFirstChild("Cost")
        if not costLabel then continue end

        if currentCurrency >= config.Cost then
            costLabel.TextColor3 = Color3.fromRGB(85, 0, 0)
        else
            costLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end

Remotes.UpdateCurrency.OnClientEvent:Connect(function(amount: number) -- แก้ไข UI ทุกครั้งที่รับข้อมูลใหม่จาก Server Side 
    currentCurrency = amount
    currencyLabel.Text = amount
    updateCostColors()
end)