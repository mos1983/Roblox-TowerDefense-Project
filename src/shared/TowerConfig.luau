return {
	-- Testing Unit
    ["TestingTower"] = {
        Cost = 50, -- ราคา
		ModelName = "TestingTower", -- ชื่อโมเดล ที่เก็บไว้ใน ReplicatedStorage
		Name = "Testing Tower", -- ชื่อ Tower
		Range = 8, -- ระยะการโจมตี
		Damage = 0.5, -- ความเสียหาย
		Cooldown = 0.5,-- เวลาในการโจมตี
		PlacementOffset = 0.5, -- offset
		Role = "Ranged", -- ประเภทการโจมตี
		ViewportZoom = 1, -- ค่ายิ่งน้อย = ซูมเข้า, ยิ่งมาก = ซูมออก
		PlacementType = "Land", -- "Land" | "Aquatic" | "Trap"
		ViewportYZoom = 0.2,
		ViewportAngle = 225,
		Image = "rbxassetid://97363391382556"
	},

	["TestingTowerWater"] = {
		Cost = 50,
		ModelName = "TestingTowerWater",
		Name = "Aquatic Testing Tower",
		Range = 8,
		Damage = 0.5,
		Cooldown = 0.5,
		PlacementOffset = 0.5,
		Role = "Ranged",
		ViewportZoom = 1,
		PlacementType = "Aquatic",
		ViewportYZoom = 0.2,
		ViewportAngle = 225,
		Image = "rbxassetid://108745142574566"
	},

	["TestingTowerTrap"] = {
		Cost = 50,
		ModelName = "TestingTowerTrap",
		Name = "Trap Testing Tower",
		Range = 8,
		Damage = 0.5,
		Cooldown = 0.5,
		PlacementOffset = 0.5,
		Role = "Ranged",
		ViewportZoom = 1,
		PlacementType = "Trap",
		ViewportYZoom = 0.2,
		ViewportAngle = 225,
		Image = "rbxassetid://132193242038439"
	},


	-- Real Unit
	["Beetle"] = {
		Cost = 80,
		ModelName = "Beetle",
		Name = "Beetle",
		Range = 6,
		Damage = 2.5,
		Cooldown = 1.6,
		PlacementOffset = 1.5,
		Role = "Melee",
		ViewportZoom = 0.2,
		PlacementType = "Land",
		ViewportYZoom = 0.05,
		ViewportAngle = 150,
		Image = "rbxassetid://134258807279166"
	}
}