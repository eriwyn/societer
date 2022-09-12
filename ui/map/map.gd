extends TextureRect

signal map_clicked

func _ready():
	var file_name = 'user://terrain/%s/map.png' % (Global.terrain_name)
	var image = Image.new()
	var err = image.load(file_name)
	if err != OK:
		print('Image load failed : %s' % (file_name))
	texture = ImageTexture.new()
	texture.create_from_image(image, Image.FORMAT_RGBA8)

func _process(_delta):
	if Input.is_action_pressed("alt_command"):
		var new_position = get_viewport().get_mouse_position()
		if new_position.x <= 512 and new_position.y <= 512:
			emit_signal("map_clicked", new_position)
