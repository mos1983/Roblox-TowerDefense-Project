return {
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
	},
	["Beetle"] = {
		Cost = 80,
		ModelName = "Beetle",
		Name = "Beetle",
		Range = 6,
		Damage = 2.5,
		Cooldown = 1.6,
		PlacementOffset = 1.5,
		Role = "Melee",
		ViewportZoom = 0.4, -- ค่ายิ่งน้อย = ซูมเข้า, ยิ่งมาก = ซูมออก
	}
}