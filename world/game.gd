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
	init_points_data()
	print(terrain)
	emit_signal("world_loaded", terrain)

func init_points_data():
	for index in terrain.get_points().size():
		terrain.get_point(index).set_elevation(find_elevation(terrain.get_point(index).point2d()))
#		points_data.append({
#			"elevation": 0,
#			"used": false,
#			"water": false,
#			"ocean": false,
#			"coast": false,
#			"mountain": false,
#			"river": false
#		})

func find_elevation(point):
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
		
	elevation = elevation * terraces
	return elevation
#
#	if points_data[point_id].elevation <= 0:
#		points_data[point_id].water = true
#
#	if points_data[point_id].elevation >= mountain_height:
#		points_data[point_id].mountain = true
