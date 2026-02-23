local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpgradeTower = Remotes:WaitForChild("UpgradeTower")
local PlaceTower = Remotes:WaitForChild("PlaceTower")
local TowerModels = ReplicatedStorage:WaitForChild("TowerModels")
local TowerConfig = require(ReplicatedStorage.Shared.TowerConfig)
local CurrencyService = require(script.Parent.CurrencyService)
local EnemyService = require(script.Parent.EnemyService)
local SellTower = Remotes:WaitForChild("SellTower")
local UpgradeTower = Remotes:WaitForChild("UpgradeTower")
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
local ButtonSFX = SoundService:WaitForChild("ButtonSFX")
local HotbarSFX = SoundService:WaitForChild("HotbarSFX")

local GameMap = workspace:WaitForChild("GameMapTemplat1")
local PlacementZone = GameMap:WaitForChild("SpawnPoints")
local PlacedTowers = workspace:WaitForChild("PlacedTowers")

local TowerAttack = Remotes:WaitForChild("TowerAttack")

local towerRadius = 3 -- ระยะห่างระหว่าง Tower

local function isValidPlacement(position: Vector3, towerType: string): boolean
    for _, part in PlacementZone:GetDescendants() do
        if not part:IsA("BasePart") then continue end

        local zoneType = part:GetAttribute("PlacementType")
        if zoneType ~= towerType then continue end

        local zonePos = part.Position
        local zoneSize = part.Size / 2
        if math.abs(position.X - zonePos.X) <= zoneSize.X
            and math.abs(position.Z - zonePos.Z) <= zoneSize.Z then
            return true

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
    
    task.spawn(function()
        while tower and tower.Parent do
            local range = tower:GetAttribute("Range") or config.Range
            local damage = tower:GetAttribute("Damage") or config.Damage
            local cooldown = tower:GetAttribute("Cooldown") or config.Cooldown

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

    local towerType = config.PlacementType or "Land"

    if not isValidPlacement(position, towerType) then
        warn(`[TowerService] {player.Name} invalid placement type`)
        return

    end

    if isOverlapping(position) then return end

    local success = CurrencyService.deductCurrency(player, config.Cost)
    if not success then return end

    local model = TowerModels:FindFirstChild(config.ModelName)
    if not model then return end

    local newTower = model:Clone()

    newTower:PivotTo(CFrame.new(position))
    newTower:SetAttribute("OwnerId", player.UserId)
    newTower:SetAttribute("TowerName", towerName)
    newTower:SetAttribute("DisplayName", config.Name)
    newTower:SetAttribute("TotalSpent", config.Cost)
    newTower:SetAttribute("Level", 1)
    newTower:SetAttribute("Damage", config.Damage)
    newTower:SetAttribute("Cooldown", config.Cooldown)
    newTower:SetAttribute("Range", config.Range)
    newTower.Parent = PlacedTowers
    startAttackLoop(newTower, player)
end)

SellTower.OnServerEvent:Connect(function(player, tower)
    if not tower or not tower.Parent then return end
    if tower.Parent ~= PlacedTowers then return end

    local ownerId = tower:GetAttribute("OwnerId")
    if ownerId ~= player.UserId then
        warn(`[TowerService] {player.Name} tried to sell someone else's tower`)
        return
    
    end

    local totalSpent = tower:GetAttribute("TotalSpent") or 0
    local refund = math.floor(totalSpent * 0.6)

    CurrencyService.addCurrency(player, refund)
    local SFX = SoundService:WaitForChild("SellSFX")
    SFX:Play()
    tower:Destroy()

    print(`[TowerService] {player.Name} sold tower for {refund}`)

end)

UpgradeTower.OnServerEvent:Connect(function(player, tower)
    if not tower or not tower.Parent then return end
    if tower.Parent ~= PlacedTowers then return end

    local ownerId = tower:GetAttribute("OwnerId")
    if ownerId ~= player.UserId then return end

    local towerName = tower:GetAttribute("TowerName")
    local currentLevel = tower:GetAttribute("Level") or 0
    local totalSpent = tower:GetAttribute("TotalSpent") or 0

    local upgradeData = UpgradeConfig[towerName]
    if not upgradeData then
        warn("[TowerService] No upgrade data for:", towerName)
        return
    end

    local nextLevel = currentLevel + 1
    local nextUpgrade = upgradeData[nextLevel]

    local success = CurrencyService.deductCurrency(player, nextUpgrade.Cost)

    if not success then
        warn("[TowerService] Not Enough Currency.")
        return
    end

    ButtonSFX:Play()

    if not nextUpgrade then
       warn("[TowerService] Max level reached")
       return
    end
    
    tower:SetAttribute("Level", nextLevel)
    tower:SetAttribute("Damage", nextUpgrade.Damage)
    tower:SetAttribute("Range", nextUpgrade.Range)
    tower:SetAttribute("Cooldown", nextUpgrade.Cooldown)
    tower:SetAttribute("TotalSpent", totalSpent + nextUpgrade.Cost)

    print(`[TowerService] {player.Name} upgraded {towerName} to level {nextLevel}`)
end)