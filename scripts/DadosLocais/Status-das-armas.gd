extends Resource
# Se preferir, pode usar "extends Script" ou até fazer um autoload.

var sword_strength_map: Dictionary = {
	1: 5,
	2: 10,
	3: 20,
	4: 30,
	5: 50
}

func get_strength_for_level(level: int) -> int:
	if sword_strength_map.has(level):
		return sword_strength_map[level]
	return 0
