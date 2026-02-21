local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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

local GameMap = workspace:WaitForChild("GameMapTemplat1")
local PlacementZone = GameMap:WaitForChild("SpawnPoints")

-- สีของ Preview โมเดล เพื่อแสดง ว่า วาง ได้ไม่ได้?
local colorValid = Color3.fromRGB(0, 255, 100)
local colorInvalid = Color3.fromRGB(255, 50, 50)

local function setPreviewColor(color: Color3) -- function ที่จะเปลี่ยนสีของ Preview Model ถ้า Conditions Met
    if not previewModel then return end
    for _, part in previewModel:GetDescendants() do
        if part:IsA("BasePart") then
            part.Color = color
            part.Transparency = 0.5
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
end

local function clearPreview() -- function ที่ลบ preview model ออก
    if previewModel then
        previewModel:Destroy()
        previewModel = nil
    end
    selectedTower = nil
    canPlace = false
end

local keyToSlot = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5
}

local slotToTower = { -- Table ในการ fixed ค่าของ slot Tower จะเปลี่ยนเป็น equip/ unequip ใน อนาคต
    [1] = "TestingTower"
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Escape then
        clearPreview()
        return
    end

    local slot = keyToSlot[input.KeyCode]
    if slot then
        local towerName = slotToTower[slot]
        if not towerName then return end
    
        if selectedTower == towerName then
            clearPreview()
            return
        end
        
        selectedTower = towerName
        createPreview(towerName)
    end
end)

mouse.Button1Down:Connect(function() -- function ทำงานเมื่อ m1 คลิก
     if not selectedTower or not canPlace then return end

    local position = previewModel.PrimaryPart.Position  -- ตำแหน่งของ Preview ที่แสดงอยู่จริงๆ
    PlaceTower:FireServer(selectedTower, position)
    clearPreview()
end)

RunService.RenderStepped:Connect(function() -- renderstepped เพื่อให้เป็น loop แบบถี่ เพื่อให้ preview model ตามเมาส์ตลอดเวลา
    if not previewModel or not selectedTower then return end -- ถ้าไม่มี selectedTower หรือ previewModel end เท่านั้น

    local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { previewModel }
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)

    if result then
        local hitPart = result.Instance
        local hitPos = result.Position

        if hitPart:IsDescendantOf(PlacementZone) then
            canPlace = true
            setPreviewColor(colorValid)
        else
            canPlace = false
            setPreviewColor(colorInvalid)
        end

        local cf, size = previewModel:GetBoundingBox()
        local bottomOffset = size.Y / 2
        previewModel:PivotTo(CFrame.new(hitPos + Vector3.new(0, bottomOffset, 0)))
    end
end)