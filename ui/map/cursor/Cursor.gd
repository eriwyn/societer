extends Sprite

func _on_Camera_camera_moved(new_location):
	var map_x = new_location.x
	var map_y = new_location.z
	position.x = map_x / 4.0
	position.y = map_y / 4.0
	
func _ready():
	scale.x = 1
	scale.y = 1
