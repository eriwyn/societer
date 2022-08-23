extends Control


func _ready():
	pass


func _on_NewButton_pressed():
	get_tree().change_scene("res://menu/NewWorld.tscn")


func _on_LoadButton_pressed():
	get_tree().change_scene("res://menu/LoadWorld.tscn")


func _on_QuitButton_pressed():
	get_tree().quit()
