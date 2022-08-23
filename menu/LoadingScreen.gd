extends Control

var thread
var world = {}
var old_step = 0

func _ready():
	thread = Thread.new()
	thread.start(self, "_generate_world")
	set_process(true)
	Global.loading.set_start_time()

func _process(_delta): 
	$ProgressBar.value = Global.loading.get_percentage()
	if (Global.loading.get_percentage() >= 100):
		Global.loading.set_end_time()
		print(Global.loading.get_elapsed_time("s"))
		get_tree().change_scene("res://world/game.tscn")

func _exit_tree():
	thread.wait_to_finish()

func _generate_world():
	world = WorldGeneration.new()
