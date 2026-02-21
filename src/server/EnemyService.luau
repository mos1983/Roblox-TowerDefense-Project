local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EnemyConfig = require(ReplicatedStorage.Shared.EnemyConfig)
local CurrencyService = require(script.Parent.CurrencyService)
local BaseService = require(script.Parent.BaseService)

local EnemyService = {}

local enemyHP: { [Model]: number } = {} -- เก็บ HP ของ enemy แยกกัน

local EnemyModels = ReplicatedStorage:WaitForChild("EnemyModels")

function EnemyService.spawnEnemy(enemyName: string, spawnPoint: Part, enemiesFolder: Folder)
    local model = EnemyModels:FindFirstChild(enemyName)
    if not model then
        warn("EnemyModel not found:", enemyName)
        return
    end

    local config = EnemyConfig[enemyName]
    if not config then
        warn("EnemyConfig not found:", enemyName)
        return
    end

    local enemy = model:Clone()
    enemy:PivotTo(CFrame.new(spawnPoint.Position))

    -- เซ็ต Attribute
    enemy:SetAttribute("EnemyName", enemyName)
    enemy:SetAttribute("MaxHP", config.HP)
    enemy:SetAttribute("CurrentHP", config.HP)
    enemy:SetAttribute("Progress", 0)

    -- เซ็ต enemyHP table ด้วย ← นี่คือสิ่งที่ขาดไป
    enemyHP[enemy] = config.HP

    -- Cleanup เมื่อถูกลบ
    enemy.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            enemyHP[enemy] = nil
        end
    end)

    enemy.Parent = enemiesFolder
    return enemy
end

function EnemyService.getHP(enemy: Model): number
    return enemyHP[enemy] or 0
end

function EnemyService.takeDamage(enemy: Model, damage: number, attacker: Player?) -- function สำหรับการลดเลือด มอน
    if not enemyHP[enemy] then return end

    enemyHP[enemy] = math.max(0, enemyHP[enemy] - damage)
    enemy:SetAttribute("CurrentHP", enemyHP[enemy]) -- อัปเดต stat มอน

    if enemyHP[enemy] <= 0 then
        if attacker then
            local config = EnemyConfig[enemy:GetAttribute("EnemyName")]
            if config then
                CurrencyService.addCurrency(attacker, config.Reward)
            end
        end

        enemyHP[enemy] = nil
        enemy:Destroy()
    end
end

game:GetService("CollectionService")

return EnemyService