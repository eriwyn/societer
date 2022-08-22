extends Control

var thread
var world = {}

func _ready():
	thread = Thread.new()
	thread.start(self, "_generate_world")
	set_process(true)
#
#	while true:
#		if "step" in world:
#			if world.step >= world.max_step:
#				break
#			print(world.step)
#			$ProgressBar.value = world.step / world.max_step * 100

func _process(delta):
	if "step" in world:
		print(world.step)
		if world.step >= 2:
			get_tree().change_scene("res://world/game.tscn")

func _exit_tree():
	thread.wait_to_finish()

func _generate_world():
	world = WorldGeneration.new()
