extends Sprite

func _on_Camera_camera_moved(new_location):
	var map_x = new_location.x
	var map_y = new_location.z
	position.x = map_x
	position.y = map_y
	pass # Replace with function body.
