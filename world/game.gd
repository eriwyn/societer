extends Spatial

signal world_loaded

export(int) var width = 2000
export(int) var height = 2000
export(int) var spacing = 20
export(int, 1, 9) var octaves = 5
export(int, 1, 30) var wavelength = 8
export(int) var border_width = 200
export(int) var terraces = 24
export(int) var terrace_height = 5
export(int) var mountain_height = 6
export(int) var river_proba = 200

var rng = RandomNumberGenerator.new()
var noise = OpenSimplexNoise.new()

var terrain

func _ready():
	rng.randomize()
	noise.seed = rng.randi()
	noise.octaves = octaves
	terrain = Terrain.new(width,height,spacing,true)
	init_data()
	print(terrain)
	emit_signal("world_loaded", terrain)

func init_data():
	for point in terrain.get_points():
		point.set_elevation(point_find_elevation(point.point2d()))
		point.set_data("water", point_is_water(point))
#		points_data.append({
#			"elevation": 0,
#			"used": false,
#			"water": false,
#			"ocean": false,
#			"coast": false,
#			"mountain": false,
#			"river": false
#		})
	fill_oceans()
	
	for triangle in terrain.get_triangles():
		triangle.set_data("elevation", triangle_find_elevation(triangle))
		triangle.set_data("water", triangle_is_water(triangle))
		triangle.set_data("ocean", false)
		for point in triangle.points():
			if point.get_data("ocean"):
				triangle.set_data("ocean", true)
		
# Point

func point_find_elevation(point):
	var border = border_width + rng.randf_range(-20.0, 20.0)
	var elevation = noise.get_noise_2d(point.x / wavelength, point.y / wavelength)
	
	if point.x < border:
		elevation -= ((border - point.x) / border) / 2.0
	if point.y < border:
		elevation -= (border - point.y) / border
	if point.x > width - border:
		elevation -= (border - (width - point.x)) / border
	if point.y > height - border:
		elevation -= (border - (height - point.y)) / border
		
	elevation = max(elevation, -1)
			
	if elevation > 0.1:
		elevation = max(pow((elevation) * 1.2, 1.5), 0.1)
		
	elevation = min(elevation, 1)
		
	# elevation = elevation * terraces
	return elevation
	
func point_is_water(point):
	if (point.get_elevation() <= 0):
		return true
	return false

# Triangle

func triangle_find_elevation(triangle):
	var elevation = 0
	for point in triangle.points():
		elevation += point.get_elevation()
	elevation /= 3.0
	return elevation

func triangle_is_water(triangle):
	if triangle.get_data("elevation") <= 0:
		return true
	return false

func fill_oceans():
	var stack = []
	for point in terrain.get_points():
		if point.point2d().x < 10 and point.get_data("water") and not point.get_data("ocean"):
			stack.append(point.get_index())
			while stack.size():
				var current_point_id = stack.pop_back()
				terrain.get_point(current_point_id).set_data("ocean", true)
				for neighbour in terrain.get_point(current_point_id).points_around():
					if neighbour.get_data("water") and not neighbour.get_data("ocean"):
						stack.append(neighbour.get_index())
			break
