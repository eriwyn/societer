extends Node

var debug = true
var terrain_name = ""
var terrain_mesh: Mesh
var terrain = Terrain.new()
# var loading = LoadingHelper.new()
var loadings = {}
var materials
var count = 0

func _ready():
	var file = File.new()
	file.open("res://world/materials/materials.json", File.READ)
	materials = JSON.parse(file.get_as_text()).result
	file.close()

# Debuging messages
func print_debug(message):
	if debug:
		print(message)


