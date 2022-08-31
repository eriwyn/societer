extends Control

var thread
var world = {}

func _ready():
	thread = Thread.new()
	thread.start(self, "_generate_world")
	set_process(true)
	Global.loadings["world_creation"] = LoadingHelper.new()
	
func _process(_delta): 
	$VBoxContainer/ProgressBar.value = Global.loadings["world_creation"].get_percentage()
	if Global.loadings["world_creation"].get_current_phase():
		$VBoxContainer/HBoxContainer/Phase.text = Global.loadings["world_creation"].get_current_phase().get_label()
	if Global.loadings["world_creation"].is_finished:
		for phase in Global.loadings["world_creation"].get_phases():
			Global.print_debug("%s : %f seconds" % [phase.get_label(), phase.get_elapsed_time("s")])
			
		Global.print_debug("Elapsed time : %f seconds" % Global.loadings["world_creation"].get_elapsed_time("s"))
		get_tree().change_scene("res://world/game.tscn")
func _exit_tree():
	thread.wait_to_finish()

func _generate_world():
	world = WorldGeneration.new()
