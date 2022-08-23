extends Control


func _ready():
	pass


func _on_CancelButton_pressed():
	get_tree().change_scene("res://menu/MainMenu.tscn")


func _on_CreateButton_pressed():
	Global.terrain_name = $VBoxContainer/LineEdit.text
	get_tree().change_scene("res://menu/LoadingScreen.tscn")
