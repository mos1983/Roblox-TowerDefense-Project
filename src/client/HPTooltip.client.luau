local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local currentTarget: Model? = nil

local function getBillboard(enemy: Model)
    local primaryPart = enemy.PrimaryPart
    if not primaryPart then return nil end
    return primaryPart:FindFirstChild("HPBillboard")
end

local function getLabel(enemy: Model)
    local billboard = getBillboard(enemy)
    if not billboard then return nil end
    return billboard:FindFirstChild("HPLabel")
end

local function showBillboard(enemy: Model)
    local billboard = getBillboard(enemy)
    if billboard then billboard.Enabled = true end
end

local function hideBillboard(enemy: Model)
    local billboard = getBillboard(enemy)
    if billboard then billboard.Enabled = false end
end

local function updateHP(enemy: Model)
    local label = getLabel(enemy)
    if not label then return end
    local current = enemy:GetAttribute("CurrentHP") or 0
    local max = enemy:GetAttribute("MaxHP") or 0
    label.Text = current .. " / " .. max
end

RunService.RenderStepped:Connect(function()
    local target = mouse.Target

    -- หา Enemy Model จาก Part ที่เมาส์ชี้
    local enemyModel = nil
    if target then
        local model = target:FindFirstAncestorOfClass("Model")
        if model and model.Parent == workspace.Enemies then
            enemyModel = model
        end
    end

    -- เมาส์ชี้ Enemy ใหม่
    if enemyModel and enemyModel ~= currentTarget then
        if currentTarget then
            hideBillboard(currentTarget)
        end
        currentTarget = enemyModel
        showBillboard(currentTarget)
    end

    -- เมาส์ออกจาก Enemy
    if not enemyModel and currentTarget then
        hideBillboard(currentTarget)
        currentTarget = nil
    end

    -- อัปเดต HP Text ตลอดเวลา
    if currentTarget then
        updateHP(currentTarget)
    end
end)