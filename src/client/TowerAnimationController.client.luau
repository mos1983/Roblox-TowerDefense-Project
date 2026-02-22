local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local TowerAttack = Remotes:WaitForChild("TowerAttack")

local animTracks = {}

local placedTowers = workspace:WaitForChild("PlacedTowers")

local function createBeam(tower: Model, target: Model)
    local shootPoint = tower:FindFirstChild("ShootingPoint", true)
    if not shootPoint then return end

    local targetAttachment = Instance.new("Attachment")
    targetAttachment.Parent = workspace.Terrain
    targetAttachment.WorldPosition = target.PrimaryPart.Position

    local beam = Instance.new("Beam")
    beam.Attachment0 = shootPoint
    beam.Attachment1 = targetAttachment
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.Segments = 1  -- เส้นตรง
    beam.LightEmission = 1
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
    beam.Parent = workspace

    task.delay(0.1, function()
        beam:Destroy()
        targetAttachment:Destroy()
    end)
end

local function loadTowerAnimation(tower:Model)
    local humanoid = tower:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local animObject = tower:FindFirstChild("AttackAnimation", true)
    if not animObject then return end

    local track = animator:LoadAnimation(animObject)
    track.Looped = false
    track.Priority = Enum.AnimationPriority.Action
    animTracks[tower] = track

    tower.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            animTracks[tower] = nil
        end
    end)
end

placedTowers.ChildAdded:Connect(function(tower)
    task.wait()
    loadTowerAnimation(tower)
end)

TowerAttack.OnClientEvent:Connect(function(tower: Model, target: Model, role: string)
    local track = animTracks[tower]
    local ShootingSFX = tower:FindFirstChild("ShootingSFX", true)
    local MeleeSFX = tower:FindFirstChild("MeleeSFX", true)

    if track then
        if track.IsPlaying then track:Stop(0) end
        track:Play()
    end

    if role == "Ranged" and target and target.Parent then
        createBeam(tower, target)
        if ShootingSFX then ShootingSFX:Play() end

    elseif role == "Melee" then
        if MeleeSFX then MeleeSFX:Play() end
    end
end)