local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyService = require(script.Parent.EnemyService)

local spawnPoint = workspace:WaitForChild("monsterSpawner")
local map = workspace:WaitForChild("GameMapTemplat1")
local path = map:WaitForChild("Path")
local waypoints = path:WaitForChild("Waypoints")

task.wait(3)

EnemyService.spawnEnemy("TestingEnemy2", spawnPoint, waypoints)

task.wait(1.2)

EnemyService.spawnEnemy("TestingEnemy2", spawnPoint, waypoints)

task.wait(1.2)

EnemyService.spawnEnemy("TestingEnemy2", spawnPoint, waypoints)

task.wait(1.2)

EnemyService.spawnEnemy("TestingEnemy2", spawnPoint, waypoints)

task.wait(12)

EnemyService.spawnEnemy("TestingEnemy3", spawnPoint, waypoints)

