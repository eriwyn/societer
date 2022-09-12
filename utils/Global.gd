extends Node

var debug = true
var terrain_name = ""
var terrain_mesh: Mesh
var terrain = Terrain.new()
var map = Map.new(terrain)
# var loading = LoadingHelper.new()
var loadings = {}
var materials
var count = 0

func _ready():
	var file = File.new()
	file.open("res://world/materials/materials.json", File.READ)
	materials = JSON.parse(file.get_as_text()).result
	file.close()
	
func polygon_area(polygon):
	var a = 0.0
	var b = 0.0
	var next = 0
	var size = polygon.size()
	if(Geometry.is_polygon_clockwise(polygon)):
		for idx in range(size-1, -1, -1):
			next = idx - 1
			if(next == 0):
				next = size - 1
			a += polygon[idx].x * polygon[next].y
			b += polygon[idx].y * polygon[next].x
	else:
		for idx in size:
			next = idx + 1
			if(next == size):
				next = 0
			a += polygon[idx].x * polygon[next].y
			b += polygon[idx].y * polygon[next].x
	return((a - b) / 2.0)

func polygon_bounding_box(polygon):
	var size = polygon.size()
	var min_x = 99999999
	var max_x = -99999999
	var min_y = 99999999
	var max_y = -99999999
	var polygon_xmin = 0
	var polygon_xmax = 1
	var polygon_ymin = 0
	var polygon_ymax = 1
	for idx in size:
		polygon_xmin = int(polygon[idx].x)
		polygon_xmax = polygon_xmin + 1
		polygon_ymin = int(polygon[idx].y)
		polygon_ymax = polygon_ymin + 1
		if(polygon_xmin < min_x):
			min_x = polygon_xmin
		if(polygon_xmax > max_x):
			max_x = polygon_xmax
		if(polygon_ymin < min_y):
			min_y = polygon_ymin
		if(polygon_ymax > max_y):
			max_y = polygon_ymax
	return(Rect2(min_x,min_y,max_x - min_x, max_y - min_y))
	
func pixel_area(voronoi, pixel):
	var polygons = Geometry.intersect_polygons_2d(voronoi, pixel)
	var number = polygons.size()
	var area = 0.0
	if(number == 0):
		return(0.0)
	if(number > 1):
		print_debug("Number of polygons : %d" % (number))
	for idx in number:
		area += polygon_area(polygons[idx])
	return(area)

# Debuging messages
func print_debug(message):
	if debug:
		print(message)


