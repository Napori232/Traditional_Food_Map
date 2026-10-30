extends Node

const WORLD_SIZE := Vector2(1600.0, 1100.0)

var _water_features: Array[Dictionary] = [
	{
		"id": "west_lake",
		"name": "西湖",
		"type": "lake",
		"points": _points([
			Vector2(455, 330), Vector2(560, 278), Vector2(690, 285), Vector2(775, 350),
			Vector2(805, 455), Vector2(760, 555), Vector2(665, 615), Vector2(555, 590),
			Vector2(480, 520), Vector2(440, 425)
		])
	},
	{
		"id": "qiantang_river",
		"name": "钱塘江",
		"type": "river",
		"points": _points([
			Vector2(610, 675), Vector2(760, 650), Vector2(900, 675), Vector2(1060, 705),
			Vector2(1230, 745), Vector2(1470, 775), Vector2(1570, 820),
			Vector2(1560, 900), Vector2(1400, 855), Vector2(1220, 815),
			Vector2(1050, 775), Vector2(890, 745), Vector2(740, 720), Vector2(610, 735)
		])
	},
	{
		"id": "grand_canal",
		"name": "京杭大运河",
		"type": "river",
		"points": _points([
			Vector2(805, 80), Vector2(830, 190), Vector2(820, 300), Vector2(845, 410),
			Vector2(830, 520), Vector2(870, 635), Vector2(900, 700)
		])
	},
	{
		"id": "qiandao_lake",
		"name": "千岛湖",
		"type": "lake",
		"points": _points([
			Vector2(180, 825), Vector2(260, 760), Vector2(355, 770), Vector2(425, 835),
			Vector2(405, 940), Vector2(320, 1005), Vector2(220, 970), Vector2(165, 900)
		])
	},
	{
		"id": "fuchun_river",
		"name": "富春江",
		"type": "river",
		"points": _points([
			Vector2(280, 665), Vector2(400, 700), Vector2(525, 745), Vector2(650, 790),
			Vector2(780, 845), Vector2(900, 890), Vector2(1060, 940)
		])
	}
]

var _districts: Array[Dictionary] = [
	{"name": "临安区", "label": Vector2(250, 260), "points": _points([Vector2(80, 120), Vector2(470, 90), Vector2(520, 330), Vector2(390, 520), Vector2(120, 470)])},
	{"name": "余杭区", "label": Vector2(470, 210), "points": _points([Vector2(470, 90), Vector2(760, 105), Vector2(775, 320), Vector2(650, 350), Vector2(520, 330)])},
	{"name": "西湖区", "label": Vector2(530, 420), "points": _points([Vector2(390, 520), Vector2(520, 330), Vector2(650, 350), Vector2(665, 610), Vector2(510, 670)])},
	{"name": "拱墅区", "label": Vector2(825, 220), "points": _points([Vector2(760, 105), Vector2(1010, 115), Vector2(1030, 350), Vector2(845, 410), Vector2(775, 320)])},
	{"name": "上城区", "label": Vector2(865, 485), "points": _points([Vector2(845, 410), Vector2(1030, 350), Vector2(1120, 560), Vector2(980, 665), Vector2(870, 635), Vector2(830, 520)])},
	{"name": "滨江区", "label": Vector2(765, 760), "points": _points([Vector2(650, 670), Vector2(870, 635), Vector2(980, 665), Vector2(900, 845), Vector2(735, 820)])},
	{"name": "萧山区", "label": Vector2(1080, 820), "points": _points([Vector2(980, 665), Vector2(1120, 560), Vector2(1450, 650), Vector2(1510, 890), Vector2(1240, 980), Vector2(900, 845)])},
	{"name": "钱塘区", "label": Vector2(1320, 500), "points": _points([Vector2(1030, 350), Vector2(1450, 300), Vector2(1530, 500), Vector2(1450, 650), Vector2(1120, 560)])},
	{"name": "临平区", "label": Vector2(1120, 210), "points": _points([Vector2(1010, 115), Vector2(1370, 120), Vector2(1450, 300), Vector2(1030, 350)])},
	{"name": "富阳区", "label": Vector2(520, 835), "points": _points([Vector2(390, 520), Vector2(510, 670), Vector2(735, 820), Vector2(650, 980), Vector2(405, 1000), Vector2(300, 850)])},
	{"name": "桐庐县", "label": Vector2(235, 620), "points": _points([Vector2(80, 470), Vector2(390, 520), Vector2(300, 850), Vector2(100, 800)])},
	{"name": "建德市", "label": Vector2(230, 900), "points": _points([Vector2(100, 800), Vector2(300, 850), Vector2(405, 1000), Vector2(180, 1060), Vector2(50, 940)])},
	{"name": "淳安县", "label": Vector2(620, 1010), "points": _points([Vector2(405, 1000), Vector2(650, 980), Vector2(900, 1040), Vector2(1080, 1080), Vector2(650, 1090), Vector2(180, 1060)])}
]

var _roads: Array[Dictionary] = [
	{"name": "杭瑞高速", "class": "expressway", "points": _points([Vector2(90, 205), Vector2(360, 175), Vector2(650, 160), Vector2(980, 175), Vector2(1390, 215)])},
	{"name": "绕城高速", "class": "expressway", "points": _points([Vector2(300, 300), Vector2(560, 200), Vector2(930, 215), Vector2(1270, 355), Vector2(1300, 680), Vector2(1080, 890), Vector2(700, 900), Vector2(390, 730)])},
	{"name": "文一西路", "class": "arterial", "points": _points([Vector2(160, 320), Vector2(410, 315), Vector2(610, 325), Vector2(790, 340)])},
	{"name": "天目山路", "class": "arterial", "points": _points([Vector2(190, 420), Vector2(395, 405), Vector2(540, 410), Vector2(770, 430), Vector2(1020, 445)])},
	{"name": "文三路", "class": "arterial", "points": _points([Vector2(335, 475), Vector2(520, 470), Vector2(710, 480), Vector2(900, 500)])},
	{"name": "延安路", "class": "arterial", "points": _points([Vector2(775, 255), Vector2(790, 380), Vector2(815, 510), Vector2(850, 635)])},
	{"name": "解放路", "class": "arterial", "points": _points([Vector2(650, 570), Vector2(825, 565), Vector2(1010, 575), Vector2(1180, 605)])},
	{"name": "庆春路", "class": "arterial", "points": _points([Vector2(675, 455), Vector2(855, 450), Vector2(1030, 465), Vector2(1170, 500)])},
	{"name": "德胜快速路", "class": "arterial", "points": _points([Vector2(665, 270), Vector2(900, 270), Vector2(1120, 290), Vector2(1350, 330)])},
	{"name": "秋涛路", "class": "arterial", "points": _points([Vector2(980, 330), Vector2(960, 480), Vector2(1000, 650), Vector2(1080, 820)])},
	{"name": "复兴路", "class": "arterial", "points": _points([Vector2(640, 650), Vector2(760, 690), Vector2(900, 735), Vector2(1040, 800)])},
	{"name": "滨盛路", "class": "arterial", "points": _points([Vector2(620, 765), Vector2(810, 770), Vector2(1010, 790), Vector2(1220, 835)])},
	{"name": "机场高速", "class": "expressway", "points": _points([Vector2(980, 520), Vector2(1120, 500), Vector2(1270, 475), Vector2(1490, 430)])},
	{"name": "曙光路", "class": "local", "points": _points([Vector2(430, 230), Vector2(470, 340), Vector2(480, 470)])},
	{"name": "保俶路", "class": "local", "points": _points([Vector2(520, 215), Vector2(545, 330), Vector2(560, 470)])},
	{"name": "凤起路", "class": "local", "points": _points([Vector2(540, 285), Vector2(720, 300), Vector2(890, 320)])},
	{"name": "体育场路", "class": "local", "points": _points([Vector2(760, 205), Vector2(930, 220), Vector2(1070, 250)])},
	{"name": "朝晖路", "class": "local", "points": _points([Vector2(860, 285), Vector2(1010, 300), Vector2(1160, 335)])},
	{"name": "艮山西路", "class": "local", "points": _points([Vector2(980, 390), Vector2(1120, 405), Vector2(1270, 420)])},
	{"name": "钱江路", "class": "local", "points": _points([Vector2(1030, 515), Vector2(1080, 620), Vector2(1130, 740)])},
	{"name": "之江路", "class": "local", "points": _points([Vector2(650, 620), Vector2(720, 700), Vector2(790, 820)])}
]

var _building_blocks: Array[Dictionary] = [
	{"rect": Rect2(245, 185, 145, 92), "style": "low"},
	{"rect": Rect2(305, 300, 120, 105), "style": "low"},
	{"rect": Rect2(205, 455, 170, 120), "style": "low"},
	{"rect": Rect2(365, 145, 110, 90), "style": "dense"},
	{"rect": Rect2(505, 130, 145, 105), "style": "dense"},
	{"rect": Rect2(675, 135, 115, 105), "style": "dense"},
	{"rect": Rect2(835, 135, 150, 105), "style": "dense"},
	{"rect": Rect2(1010, 150, 175, 112), "style": "dense"},
	{"rect": Rect2(1210, 180, 150, 105), "style": "low"},
	{"rect": Rect2(830, 350, 125, 105), "style": "dense"},
	{"rect": Rect2(1000, 355, 145, 130), "style": "dense"},
	{"rect": Rect2(1170, 370, 150, 120), "style": "low"},
	{"rect": Rect2(840, 510, 135, 108), "style": "dense"},
	{"rect": Rect2(1010, 530, 150, 120), "style": "dense"},
	{"rect": Rect2(1195, 545, 155, 115), "style": "low"},
	{"rect": Rect2(430, 665, 155, 105), "style": "low"},
	{"rect": Rect2(620, 835, 160, 88), "style": "low"},
	{"rect": Rect2(810, 865, 170, 92), "style": "low"},
	{"rect": Rect2(1040, 820, 165, 110), "style": "low"},
	{"rect": Rect2(1260, 760, 155, 105), "style": "low"},
	{"rect": Rect2(104, 255, 120, 90), "style": "park"},
	{"rect": Rect2(315, 245, 95, 62), "style": "park"},
	{"rect": Rect2(330, 660, 120, 78), "style": "park"},
	{"rect": Rect2(1180, 245, 105, 70), "style": "park"}
]

var _landmarks: Array[Dictionary] = [
	{"name": "西湖", "type": "water", "position": Vector2(610, 435)},
	{"name": "灵隐寺", "type": "temple", "position": Vector2(450, 245)},
	{"name": "雷峰塔", "type": "tower", "position": Vector2(590, 570)},
	{"name": "西溪湿地", "type": "park", "position": Vector2(390, 300)},
	{"name": "武林广场", "type": "square", "position": Vector2(825, 350)},
	{"name": "杭州东站", "type": "station", "position": Vector2(1040, 325)},
	{"name": "杭州奥体中心", "type": "stadium", "position": Vector2(900, 750)},
	{"name": "萧山国际机场", "type": "airport", "position": Vector2(1390, 445)},
	{"name": "良渚遗址", "type": "heritage", "position": Vector2(520, 135)}
]

## Returns the complete world size used by the map layers.
func GetWorldSize() -> Vector2:
	return WORLD_SIZE

## Returns water polygons and rivers used by the water scene layer.
func GetWaterFeatures() -> Array[Dictionary]:
	return _water_features.duplicate(true)

## Returns administrative district polygons used by the district scene layer.
func GetDistricts() -> Array[Dictionary]:
	return _districts.duplicate(true)

## Returns named roads and their map geometry.
func GetRoads() -> Array[Dictionary]:
	return _roads.duplicate(true)

## Returns urban blocks used to generate replaceable Q-style building clusters.
func GetBuildingBlocks() -> Array[Dictionary]:
	return _building_blocks.duplicate(true)

## Returns large Hangzhou landmarks shown above the base map.
func GetLandmarks() -> Array[Dictionary]:
	return _landmarks.duplicate(true)

func _points(points: Array[Vector2]) -> PackedVector2Array:
	return PackedVector2Array(points)
