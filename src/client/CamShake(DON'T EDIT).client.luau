local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CameraShake = Remotes:WaitForChild("CameraShake")

-- State ของ Shake
local shakeOffset = CFrame.identity
local shakeMagnitude = 0
local shakeDuration = 0
local shakeElapsed = 0

local function startShake(magnitude: number, duration: number)
    shakeMagnitude = magnitude
    shakeDuration = duration
    shakeElapsed = 0
end

-- Loop ขยับ Camera
RunService.RenderStepped:Connect(function(dt)
    if shakeElapsed >= shakeDuration then
        shakeOffset = CFrame.identity
        return
    end

    shakeElapsed += dt

    -- ค่อยๆ ลดความแรงลงตามเวลา
    local progress = shakeElapsed / shakeDuration
    local currentMagnitude = shakeMagnitude * (1 - progress)

    -- สุ่มทิศทาง
    local rx = (math.random() - 0.5) * 2 * currentMagnitude
    local ry = (math.random() - 0.5) * 2 * currentMagnitude
    local rz = (math.random() - 0.5) * 2 * currentMagnitude

    shakeOffset = CFrame.Angles(rx, ry, rz)
    camera.CFrame = camera.CFrame * shakeOffset
end)

-- รับ Event จาก Server
CameraShake.OnClientEvent:Connect(function(damage: number)
    -- คำนวณความแรงตาม damage ที่ได้รับ
    local magnitude = math.clamp(damage / 500, 0.02, 0.15)
    local duration = math.clamp(damage / 300, 0.3, 1.0)
    startShake(magnitude, duration)
end)