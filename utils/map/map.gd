extends Reference

# Build terrain from delaunay graph
class_name Map

var image
var terrain

# Called when the node enters the scene tree for the first time.
func _init(a_terrain):
	self.terrain = a_terrain
	a_terrain.set_data("map",self)

func gen_map():
	Global.loadings["world_creation"].new_phase("Generation de la carte...", terrain._points.size())
	image = Image.new()
	image.create(terrain._width,terrain._height,false,Image.FORMAT_RGBA8)
	image.lock()
	image.fill(Color('#5aa6ca'))
	image.unlock()
	var file_name = "user://terrain/%s/map.png" % (terrain.get_name())

	for center in terrain.get_centers():
		if not center.get_data("water"):
			var voronoi = center.get_data("voronoi")
			var voronoi_bounding_box = center.get_data("voronoi_bounding_box")
#			print_debug("Creat voronoi image")
			var voronoi_image = Image.new()
			voronoi_image.create(int(voronoi_bounding_box.size.x), int(voronoi_bounding_box.size.y),false,Image.FORMAT_RGBA8)
			voronoi_image.lock()
			for x in int(voronoi_bounding_box.size.x):
				for y in int(voronoi_bounding_box.size.y):
					var pixel = []
					pixel.append(Vector2(voronoi_bounding_box.position.x + x, voronoi_bounding_box.position.y + y))
					pixel.append(Vector2(voronoi_bounding_box.position.x + x + 1, voronoi_bounding_box.position.y + y))
					pixel.append(Vector2(voronoi_bounding_box.position.x + x + 1, voronoi_bounding_box.position.y + y + 1))
					pixel.append(Vector2(voronoi_bounding_box.position.x + x, voronoi_bounding_box.position.y + y + 1))
					var alpha = Global.pixel_area(voronoi, pixel)
#					print_debug("Alpha : %f" % (alpha))
					var color
					if center.get_data("coast"):
						color = Color(0.708, 0.646, 0.138, alpha)
					else:
						color = Color(0.253, 0.621, 0.229, alpha)
					voronoi_image.set_pixel(x,y,color)
			image.lock()
			image.blend_rect(voronoi_image,Rect2(0.0,0.0,voronoi_bounding_box.size.x,voronoi_bounding_box.size.y),voronoi_bounding_box.position)
			image.unlock()
			voronoi_image.unlock()
		Global.loadings["world_creation"].increment_step()
	image.save_png(file_name)
