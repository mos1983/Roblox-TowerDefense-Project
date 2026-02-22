local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlaceTower = Remotes:WaitForChild("PlaceTower")
local TowerModels = ReplicatedStorage:WaitForChild("TowerModels")
local TowerConfig = require(ReplicatedStorage.Shared.TowerConfig)

-- State ของ Tower ที่ Highlight(Selected)
local selectedTower: string? = nil -- ชื่อ Tower ที่ Highlight
local previewModel : Model? = nil -- Model Preview
local canPlace = false -- วางได้ไหม เช็คว่าอยู่ใน Zone หรือป่าว
local towerRadius = 3
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("ScreenGui")
local hotbar = screenGui:WaitForChild("Hotbar")
local selectedSlot = 0

local GameMap = workspace:WaitForChild("GameMapTemplat1")
local PlacementZone = GameMap:WaitForChild("SpawnPoints")

-- สีของ Preview โมเดล เพื่อแสดง ว่า วาง ได้ไม่ได้?
local colorValid = Color3.fromRGB(0, 255, 100)
local colorInvalid = Color3.fromRGB(255, 50, 50)

local SLOT_SELECTED_OFFSET = UDim2.new(0, 0, 0, -10) -- ขยับขึ้น 10px
local slotOriginalPosition = {} -- เก็บ Position เดิมของแต่ละ Slot

local rangeCircle: Part? = nil

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

local function setupViewport(slot: Frame, towerName: string)
    local imageButton = slot:FindFirstChildOfClass("ImageButton")
    if not imageButton then return end

    local viewport = imageButton:FindFirstChildOfClass("ViewportFrame")
    if not viewport then return end

    for _, child in viewport:GetChildren() do
        if child:IsA("Model") or child:IsA("Camera") then
            child:Destroy()
        end
    end

    local model = TowerModels:FindFirstChild(towerName)
    if not model then return end

    local config = TowerConfig[towerName]
    local zoom = config and config.ViewportZoom or 1.2 -- fallback ถ้าไม่มีค่า

    local clone = model:Clone()
    clone.Parent = viewport

    local viewportCamera = Instance.new("Camera")
    viewportCamera.Parent = viewport
    viewport.CurrentCamera = viewportCamera

    local cf, size = clone:GetBoundingBox()
    local distance = size.Magnitude * zoom

    -- หมุน Model ด้วย RunService
    local angle = 0
    game:GetService("RunService").RenderStepped:Connect(function(dt)
        if not clone or not clone.Parent then return end

        angle += dt * 60 -- ความเร็วหมุน องศาต่อวินาที ปรับได้

        viewportCamera.CFrame = CFrame.new(
            cf.Position + Vector3.new(
                math.sin(math.rad(angle)) * distance,
                size.Y * 0.3,
                math.cos(math.rad(angle)) * distance
            ),
            cf.Position
        )
    end)
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

        if towerName then
            local config = TowerConfig[towerName]
            if costLabel then
                costLabel.Text = tostring(config.Cost)
            end
            setupViewport(slot, towerName)
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

        local inZone = hitPart:IsDescendantOf(PlacementZone)
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