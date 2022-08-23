extends Spatial

func _ready():
	var mi = Global.terrain.get_data("mesh")
	add_child(mi)
