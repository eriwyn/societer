extends Control


func _ready():
	pass


func _on_NewButton_pressed():
	get_tree().change_scene("res://world/game.tscn")


func _on_LoadButton_pressed():
	pass # Replace with function body.


func _on_QuitButton_pressed():
	get_tree().quit()
