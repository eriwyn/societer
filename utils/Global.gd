extends Node

var debug = true
var terrain_name = ""
var terrain = Terrain.new()

# Debuging messages
func print_debug(message):
	if debug:
		print(message)

