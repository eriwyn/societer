extends Node

var debug = true
var terrain_name = ""
var terrain_mesh: Mesh
var terrain = Terrain.new()
var loading = loading_helper.new()

# Debuging messages
func print_debug(message):
	if debug:
		print(message)

class loading_helper:
	var _step = 0
	var _max_step = 0
	var _start_time = 0
	var _end_time = 0

	func _init():
		pass

	func reset():
		_step = 0
		_max_step = 0
		_start_time = 0
		_end_time = 0

	func set_step(number: int):
		_step = number

	func get_step():
		return _step

	func increment_step():
		_step += 1

	func set_max_step(number: int):
		_max_step = number

	func get_max_step():
		return _max_step

	func set_start_time():
		_start_time = OS.get_ticks_msec()

	func get_start_time():
		return _start_time
	
	func set_end_time():
		_end_time = OS.get_ticks_msec()

	func get_end_time():
		return _end_time

	func get_elapsed_time(unit):
		var elapsed_time = _end_time - _start_time
		if unit == "s":
			elapsed_time = float(elapsed_time) / 1000.0

		return elapsed_time

	func get_percentage():
		if get_max_step() > 0:
			return float(get_step()) / float(get_max_step()) * 100
		return 0
