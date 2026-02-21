local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveConfig = require(ReplicatedStorage.Shared.WaveConfig)
local CurrencyService = require(script.Parent.CurrencyService)
local EnemyService = require(script.Parent.EnemyService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WaveStarted = Remotes:WaitForChild("WaveStarted")
local WaveCompleted = Remotes:WaitForChild("WaveCompleted")
local UpdateCountdown = Remotes:WaitForChild("UpdateCountdown")

local spawnPoint = workspace:WaitForChild("monsterSpawner")
local enemiesFolder = workspace:WaitForChild("Enemies")

local WaveService = {}

local currentWave = 0
local isWaveActive = false
local activeEnemies = 0

local function spawnEnemy(enemyName: string)
    local enemy = EnemyService.spawnEnemy(enemyName, spawnPoint, enemiesFolder)
    if not enemy then return end

    activeEnemies += 1

    enemy.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            activeEnemies = math.max(0, activeEnemies - 1)
        end
    end)
end

local function giveRewards()
    local reward = WaveConfig.getReward(currentWave)
    for _, player in Players:GetPlayers() do
        CurrencyService.addCurrency(player, reward)
    end
    WaveCompleted:FireAllClients(currentWave, reward)
    print(`[WaveService] Wave {currentWave} completed! Reward: {reward}`)
end

function WaveService.startWave()
    if isWaveActive then return end

    currentWave += 1
    isWaveActive = true
    activeEnemies = 0

    local waveData = WaveConfig.waves[currentWave]
    if not waveData then
        print("[WaveService] All waves completed!")
        isWaveActive = false
        return
    end

    print(`[WaveService] Wave {currentWave} started!`)
    WaveStarted:FireAllClients(currentWave)

    -- Spawn Enemy ใน task.spawn เพื่อไม่ block timer
    task.spawn(function()
        for _, group in waveData do
            for i = 1, group.count do
                spawnEnemy(group.enemyName)
                task.wait(group.interval)
            end
        end
    end)

    local timeleft = WaveConfig.waveDuration
    local enemiesFinishedEarly = false

    for i = timeleft, 1, -1 do
        UpdateCountdown:FireAllClients(i, false)

        if activeEnemies <= 0 and i > WaveConfig.shortCountdown then
            enemiesFinishedEarly = true
            break
        end

        task.wait(1)
    end

    giveRewards()
    isWaveActive = false

    if enemiesFinishedEarly then
        print("[WaveService] All enemies cleared! Starting short countdown...")
        for i = WaveConfig.shortCountdown, 1, -1 do
            UpdateCountdown:FireAllClients(i, true)
            task.wait(1)
        end
    end

    UpdateCountdown:FireAllClients(0, false)
    WaveService.startWave()
end

return WaveService