extends Control


func _ready():
	for terrain in Global.terrain.list():
		var name = terrain.name
		var button = Button.new()
		button.text = terrain.name
		button.connect("pressed", self, "_button_pressed", [name])
		$VBoxContainer/ScrollContainer/WorldList.add_child(button)

func _on_CancelButton_pressed():
	get_tree().change_scene("res://menu/MainMenu.tscn")


func _button_pressed(name):
	Global.terrain_name = name
	get_tree().change_scene("res://utils/world_generation/WorldGeneration.tscn")
