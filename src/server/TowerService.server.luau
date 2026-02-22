local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceTower = Remotes:WaitForChild("PlaceTower")
local TowerModels = ReplicatedStorage:WaitForChild("TowerModels")
local TowerConfig = require(ReplicatedStorage.Shared.TowerConfig)
local CurrencyService = require(script.Parent.CurrencyService)
local EnemyService = require(script.Parent.EnemyService)

local GameMap = workspace:WaitForChild("GameMapTemplat1")
local PlacementZone = GameMap:WaitForChild("SpawnPoints")
local PlacedTowers = workspace:WaitForChild("PlacedTowers")

local TowerAttack = Remotes:WaitForChild("TowerAttack")

local towerRadius = 3 -- ระยะห่างระหว่าง Tower

local function isInZone(position: Vector3): boolean -- function ที่เช็คว่า Tower อยู่ใน PlacementZone หรือป่าว
    for _, part in PlacementZone:GetChildren() do
        if part:IsA("BasePart") then
            local zonePos = part.Position
            local zoneSize = part.Size / 2
            if math.abs(position.X - zonePos.X) <= zoneSize.X
                and math.abs(position.Z - zonePos.Z) <= zoneSize.Z then
                return true
            end
        end
    end
    return false
end

local function isOverlapping(position: Vector3): boolean -- functio ที่เช็คว่า Tower ทับกันไหม
    for _, tower in PlacedTowers:GetChildren() do
        if tower:IsA("Model") and tower.PrimaryPart then
            local dist = (tower.PrimaryPart.Position - position).Magnitude
            if dist < towerRadius then
                return true
            end
        end
    end
    return false
end

local function getTarget(tower: Model, range: number): Model? -- function เพื่อหา target ที่ condition met ในการ โจมตี
    local enemies = workspace.Enemies:GetChildren()
    local bestTarget = nil
    local bestProgress = -1

    for _, enemy in enemies do
        if not enemy:IsA("Model") or not enemy.PrimaryPart then continue end

        local dist = (enemy.PrimaryPart.Position - tower.PrimaryPart.Position).Magnitude
        if dist <= range then
            local progress = enemy:GetAttribute("Progress") or 0
            if progress > bestProgress then
                bestProgress = progress
                bestTarget = enemy
            end
        end
    end

    return bestTarget
end

local function faceTarget(tower: Model, target: Model) -- ให้ tower หันไปมอง target
    local targetPos = target.PrimaryPart.Position
    local towerPos = tower.PrimaryPart.Position
    local lookCFrame = CFrame.lookAt(
        towerPos,
        Vector3.new(targetPos.X, towerPos.Y, targetPos.Z)
    )
    tower:PivotTo(lookCFrame)
end

local function startAttackLoop(tower: Model, owner: Player)
    local towerName = tower:GetAttribute("TowerName")
    local config = TowerConfig[towerName]
    if not config then return end

    local range = config.Range
    local damage = config.Damage
    local cooldown = config.Cooldown

    task.spawn(function()
        while tower and tower.Parent do
            local target = getTarget(tower, range)

            if target then
                faceTarget(tower, target)
                EnemyService.takeDamage(target, damage, owner)

                local config = TowerConfig[towerName]

                TowerAttack:FireAllClients(tower, target, config.Role)
            end

            task.wait(cooldown)
        end
    end)
end

PlaceTower.OnServerEvent:Connect(function(player, towerName, position)
    local config = TowerConfig[towerName]

    if not config then return end

    if not isInZone(position) then return end

    if isOverlapping(position) then return end

    local success = CurrencyService.deductCurrency(player, config.Cost)
    if not success then return end

    local model = TowerModels:FindFirstChild(config.ModelName)
    if not model then return end

    local newTower = model:Clone()

    newTower:PivotTo(CFrame.new(position))
    newTower:SetAttribute("OwnerId", player.UserId)
    newTower:SetAttribute("TowerName", towerName)
    newTower:SetAttribute("TotalSpent", config.Cost)
    newTower.Parent = PlacedTowers
    startAttackLoop(newTower, player)
end)