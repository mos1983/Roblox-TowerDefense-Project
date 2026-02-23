local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceTower = Remotes:WaitForChild("PlaceTower")
local TowerModels = ReplicatedStorage:WaitForChild("TowerModels")
local TowerConfig = require(ReplicatedStorage.Shared.TowerConfig)
local SellTower = Remotes:WaitForChild("SellTower")
local UpgradeTower = Remotes:WaitForChild("UpgradeTower")
local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)

-- State ของ Tower ที่ Highlight(Selected)
local selectedTower: string? = nil -- ชื่อ Tower ที่ Highlight
local previewModel : Model? = nil -- Model Preview
local canPlace = false -- วางได้ไหม เช็คว่าอยู่ใน Zone หรือป่าว
local towerRadius = 3
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("ScreenGui")
local hotbar = screenGui:WaitForChild("Hotbar")

local screenGui1 = playerGui:WaitForChild("ScreenGui1")
local towerPanel = screenGui1:WaitForChild("Frame")
local sellButton = towerPanel:WaitForChild("Sell")
local upgradeButton = towerPanel:WaitForChild("Upgrade")
local nameLabel = towerPanel:WaitForChild("Name")
local lvLabel = towerPanel:WaitForChild("LV")
local totalLabel = towerPanel:WaitForChild("Total")
local attackLabel = towerPanel:WaitForChild("Attack")
local rangeLabel = towerPanel:WaitForChild("Range")
local speedLabel = towerPanel:WaitForChild("Speed")
local attackUpLabel = towerPanel:WaitForChild("AttackUp")
local speedUpLabel = towerPanel:WaitForChild("SpeedUp")
local rangeUpLabel = towerPanel:WaitForChild("RangeUp")
local typeLabel = towerPanel:WaitForChild("Tpye")
local tower3D = towerPanel:WaitForChild("Tower3D")
local closePanel = towerPanel:WaitForChild("X")

local selectedSlot = 0
local selectedPlacedTower: Model? = nil

local ButtonSFX = SoundService:WaitForChild("ButtonSFX")
local HotbarSFX = SoundService:WaitForChild("HotbarSFX")

local GameMap = workspace:WaitForChild("GameMapTemplat1")
local PlacementZone = GameMap:WaitForChild("SpawnPoints")

-- สีของ Preview โมเดล เพื่อแสดง ว่า วาง ได้ไม่ได้?
local colorValid = Color3.fromRGB(0, 255, 100)
local colorInvalid = Color3.fromRGB(255, 50, 50)

towerPanel.Position = UDim2.new(-.3, 0, 0, 0)

local SLOT_SELECTED_OFFSET = UDim2.new(0, 0, 0, -10) -- ขยับขึ้น 10px
local PANEL_SELECTED_OFFSET = UDim2.new(.3, 0, 0, 0)
local panelOriginalPosition = towerPanel.Position
local slotOriginalPosition = {} -- เก็บ Position เดิมของแต่ละ Slot

local rangeCircle: Part? = nil

local function setupViewport(container, towerName: string)
    if not container then return end

    -- หา ViewportFrame ไม่ว่าจะส่งอะไรมา
    local viewport
    if container:IsA("ViewportFrame") then
        viewport = container
    else
        local imageButton = container:FindFirstChildOfClass("ImageButton")
        if imageButton then
            viewport = imageButton:FindFirstChildOfClass("ViewportFrame")
        end
    end

    if not viewport then return end

    -- ล้างของเก่า
    for _, child in viewport:GetChildren() do
        if child:IsA("WorldModel") or child:IsA("Camera") then
            child:Destroy()
        end
    end

    local model = TowerModels:FindFirstChild(towerName)
    if not model then return end

    local config = TowerConfig[towerName]
    local zoom = config and config.ViewportZoom or 1.2

    task.spawn(function()
        local worldModel = Instance.new("WorldModel")
        worldModel.Parent = viewport

        local clone = model:Clone()
        clone.Parent = worldModel

        task.wait(0.1)

        local cf, size = clone:GetBoundingBox()
        local distance = size.Magnitude * zoom

        local viewportCamera = Instance.new("Camera")
        viewportCamera.Parent = viewport
        viewport.CurrentCamera = viewportCamera

        local angleRad = math.rad(config and config.ViewportAngle or 45)
        local yZoom = config and config.ViewportYZoom or 0.3

        viewportCamera.CFrame = CFrame.new(
            cf.Position + Vector3.new(
                math.sin(angleRad) * distance,
                size.Y * yZoom,
                math.cos(angleRad) * distance
            ),
            cf.Position
        )

        local humanoid = clone:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local idleAnim = clone:FindFirstChild("IdleAnimation", true)
                if idleAnim then
                    local track = animator:LoadAnimation(idleAnim)
                    track.Looped = true
                    track.Priority = Enum.AnimationPriority.Idle
                    track:Play()
                end
            end
        end
    end)
end

local function showTowerPanel(tower: Model)
    selectedPlacedTower = tower

    local towerName = tower:GetAttribute("TowerName") or "Unknown"
    setupViewport(tower3D, towerName) -- เรียก setupViewport เดิม
    local totalSpent = tower:GetAttribute("TotalSpent") or 0
    local ownerId = tower:GetAttribute("OwnerId")
    local currentLevel = tower:GetAttribute("Level") or 0
    local isOwner = ownerId == player.UserId

    local config = TowerConfig[towerName]
    local upgradeData = UpgradeConfig[towerName]
    local nextUpgrade = upgradeData and upgradeData[currentLevel + 1]

    nameLabel.Text = tower:GetAttribute("DisplayName")
    lvLabel.Text = "LV: " .. currentLevel
    totalLabel.Text = "💰Total Spent: ".. totalSpent
    
    attackLabel.Text = "🗡️ATK: " .. (tower:GetAttribute("Damage") or "?")
    rangeLabel.Text = "🎯RNG: " .. (tower:GetAttribute("Range") or "?")
    speedLabel.Text = "⏳ATKSPD: " .. (tower:GetAttribute("Cooldown") or "?")

    if nextUpgrade then
        attackUpLabel.Text = "→ " .. nextUpgrade.Damage
        rangeUpLabel.Text = "→ " .. nextUpgrade.Range
        speedUpLabel.Text = "→ " .. nextUpgrade.Cooldown
        upgradeButton.Upgrade.Text = "🚀Upgrade: " .. nextUpgrade.Cost
    else
        attackUpLabel.Text = "MAX"
        rangeUpLabel.Text = "MAX"
        speedUpLabel.Text = "MAX"
        upgradeButton.Upgrade.Text = "Max Level"
    end

    local sellValue = math.floor(totalSpent * 0.6)
    sellButton.Sell.Text = "💰Sell: " .. sellValue

    sellButton.Active = isOwner
    upgradeButton.Active = isOwner

    TweenService:Create(
    towerPanel,
    TweenInfo.new(.5, Enum.EasingStyle.Quad),
    { Position = panelOriginalPosition + PANEL_SELECTED_OFFSET }
    ):Play()

end

local function hideTowerPanel()
    selectedPlacedTower = nil
    TweenService:Create(
    towerPanel,
    TweenInfo.new(.5, Enum.EasingStyle.Quad),
    { Position = panelOriginalPosition }
    ):Play()

end

local function animateSlot(slotIndex: number)
    for i = 1, 5 do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if not slot then continue end

        local imageButton = slot:FindFirstChildOfClass("ImageButton")
        if not imageButton then continue end

        -- เก็บ Position เดิมครั้งแรก
        if not slotOriginalPosition[i] then
            slotOriginalPosition[i] = imageButton.Position
        end

        if i == slotIndex then
            -- ขยับขึ้น
            TweenService:Create(
                imageButton,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                { Position = slotOriginalPosition[i] + SLOT_SELECTED_OFFSET }
            ):Play()
        else
            -- กลับที่เดิม
            TweenService:Create(
                imageButton,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                { Position = slotOriginalPosition[i] }
            ):Play()
        end
    end
end

local function createRangeCircle(range: number) -- function ในการสร้าง part สำหรับเป็น indicator บอก ระยะ
    if rangeCircle then
        rangeCircle:Destroy()
        rangeCircle = nil
    end

    local circle = Instance.new("Part")
    circle.Name = "RangeCircle"
    circle.Shape = Enum.PartType.Cylinder
    circle.Size = Vector3.new(0.1, range * 2, range * 2)
    circle.Anchored = true
    circle.CanCollide = false
    circle.CanQuery = false -- ไม่ให้ Raycast ชน
    circle.CastShadow = false
    circle.Color = Color3.fromRGB(0, 255, 0)
    circle.Transparency = 0.8
    circle.Material = Enum.Material.SmoothPlastic
    circle.Parent = workspace

    local texture = Instance.new("Texture")
    texture.Name = "RangeTexture"
    texture.Texture = "rbxassetid://14915346373" 
    texture.Face = Enum.NormalId.Right
    texture.Color3 = Color3.fromRGB(0, 255, 0)
    texture.StudsPerTileU = range * 2
    texture.StudsPerTileV = range * 2
    texture.Parent = circle

    rangeCircle = circle
end

local function setPreviewColor(color: Color3)
    if not previewModel then return end
    for _, part in previewModel:GetDescendants() do
        if part:IsA("BasePart") then
            if part.Name == "SizeBox" then
                part.Transparency = 1
            else
                part.Color = color
                part.Transparency = 0.5
            end
            part.CanCollide = false
        end
    end
end

local function createPreview(towerName: string)
    if previewModel then
        previewModel:Destroy()
        previewModel = nil
    end

    local model = TowerModels:FindFirstChild(towerName)
    if not model then return end

    previewModel = model:Clone()
    previewModel.Parent = workspace
    setPreviewColor(colorInvalid)

    local config = TowerConfig[towerName]
    if config and config.Range then
        createRangeCircle(config.Range)
    end
end

local function highlightSlot(slotIndex: number)
    for i = 1, 5 do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if not slot then continue end
        -- เปลี่ยนสี Border หรือ Background
        slot.BackgroundColor3 = if i == slotIndex
            then Color3.fromRGB(255, 255, 255)  -- สีทอง = selected
            else Color3.fromRGB(50, 50, 50)   -- สีเทา = ปกติ
    end
    animateSlot(slotIndex)
    HotbarSFX:Play()
end

local function clearPreview() -- function ที่ลบ preview model ออก
    if previewModel then
        previewModel:Destroy()
        previewModel = nil
    end

    if rangeCircle then
        rangeCircle:Destroy()
        rangeCircle = nil
    end

    selectedTower = nil
    canPlace = false
    selectedSlot = 0
    highlightSlot(0) -- reset ทุก slot
end

local keyToSlot = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5
}

local SlotConfig = require(ReplicatedStorage.Shared.SlotConfig)

local function setupHotbar()
    for i = 1, 5 do
        local slot = hotbar:FindFirstChild("Slot" .. i)
        if not slot then continue end

        local towerName = SlotConfig[i]
        local imageButton = slot:FindFirstChildOfClass("ImageButton")
        local costLabel = slot:FindFirstChild("ImageButton"):FindFirstChild("Cost")
        local pfp = imageButton:FindFirstChild("Pfp")

        if towerName then
            local config = TowerConfig[towerName]
            if costLabel then
                costLabel.Text = tostring(config.Cost)
            end
            if pfp then
                pfp.Image = config.Image or "rbxassetid://108735403983681"
            end
        else
            if costLabel then costLabel.Text = "-" end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Q then
        clearPreview()
        return
    end

    local slot = keyToSlot[input.KeyCode]
    if slot then
        local towerName = SlotConfig[slot]
        if not towerName then return end

        if selectedTower == towerName then
            clearPreview()
            return
        end

        selectedTower = towerName
        selectedSlot = slot
        highlightSlot(slot) -- highlight slot ที่กด
        createPreview(towerName)
    end
end)

mouse.Button1Down:Connect(function() -- function ทำงานเมื่อ m1 คลิก
     if not selectedTower or not canPlace then return end

    local position = previewModel.PrimaryPart.Position  -- ตำแหน่งของ Preview ที่แสดงอยู่จริงๆ
    PlaceTower:FireServer(selectedTower, position)
    clearPreview()
end)

local function isOverlapping(position: Vector3): boolean
    local placedTowers = workspace:FindFirstChild("PlacedTowers")
    if not placedTowers then return false end

    for _, tower in placedTowers:GetChildren() do
        if tower:IsA("Model") and tower.PrimaryPart then
            local dist = (tower.PrimaryPart.Position - position).Magnitude
            if dist < towerRadius then
                return true
            end
        end
    end
    return false
end

setupHotbar()

RunService.RenderStepped:Connect(function()
    if not previewModel or not selectedTower then return end

    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { previewModel }
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)

    if result then
        local hitPart = result.Instance
        local hitPos = result.Position

        local cf, size = previewModel:GetBoundingBox()
        local config = TowerConfig[selectedTower]
        local bottomOffset = config and config.PlacementOffset or (size.Y / 2) -- fallback เป็น GetBoundingBox ถ้าไม่มีค่า
        local placementPos = hitPos + Vector3.new(0, bottomOffset, 0)

        previewModel:PivotTo(CFrame.new(placementPos))

        if rangeCircle then
            rangeCircle.CFrame = CFrame.new(placementPos) * CFrame.Angles(0, 0, math.rad(90))
        end

        local inZone = false

        if hitPart:IsDescendantOf(PlacementZone) then
            local zoneType = hitPart:GetAttribute("PlacementType")
                or hitPart.Parent:GetAttribute("PlacementType")

            local towerType = config and config.PlacementType or "Land"

            if zoneType == towerType then
                inZone = true
            end
        end

        local overlapping = isOverlapping(placementPos)

        if inZone and not overlapping then
            canPlace = true
            setPreviewColor(colorValid)
        else
            canPlace = false
            setPreviewColor(colorInvalid)
        end

    end
end)

for i = 1, 5 do
    local slot = hotbar:FindFirstChild("Slot" .. i)
    if not slot then continue end

    local imageButton = slot:FindFirstChildOfClass("ImageButton")
    if not imageButton then continue end

    imageButton.MouseButton1Click:Connect(function()
        local towerName = SlotConfig[i]
        if not towerName then return end

        if selectedTower == towerName then
            clearPreview()
            return
        end

        selectedTower = towerName
        selectedSlot = i
        highlightSlot(i)
        createPreview(towerName)
    end)
end

mouse.Button1Down:Connect(function()
    if selectedTower then return end

    local target = mouse.Target
    if not target then
        hideTowerPanel()
        return
    end

    local model = target:FindFirstAncestorOfClass("Model")
    if model and model.Parent == workspace.PlacedTowers then
        showTowerPanel(model)
    else
        hideTowerPanel()
    end
end)

sellButton.MouseButton1Click:Connect(function()
    if not selectedPlacedTower then return end
    if not sellButton.Active then return end

    SellTower:FireServer(selectedPlacedTower)
    hideTowerPanel()
end)

upgradeButton.MouseButton1Click:Connect(function()
    if not selectedPlacedTower then return end
    if not upgradeButton.Active then return end

    UpgradeTower:FireServer(selectedPlacedTower)

    task.wait(.1)
    if selectedPlacedTower and selectedPlacedTower.Parent then
        showTowerPanel(selectedPlacedTower)
    end

end)

closePanel.MouseButton1Click:Connect(function()
    hideTowerPanel()
end)