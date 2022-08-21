extends Node

signal world_loaded

export(int) var width = 2000
export(int) var height = 2000
export(int) var spacing = 20
export(int, 1, 9) var octaves = 5
export(int, 1, 30) var wavelength = 8
export(int) var border_width = 200
export(int) var terraces = 10
export(int) var terrace_height = 5
export(float) var mountain_height = 6.0 / 24.0
export(int) var river_proba = 200

var rng = RandomNumberGenerator.new()
var noise = OpenSimplexNoise.new()

var terrain

func _ready():
	rng.randomize()
	noise.seed = rng.randi()
	noise.octaves = octaves
	
	var terrain_name="bonjour90"
	terrain = Terrain.new()

	print(terrain.list())
	
	if terrain.exists(terrain_name):
		terrain.load(terrain_name)
	else:
		terrain.create(width,height,spacing,terrain_name)

	if terrain.is_created() or terrain.is_loaded():
		init_data()
		add_trees()
		emit_signal("world_loaded", terrain)
	else:
		Global.print_debug("Pas de terrain, pas de construction ...")
		Global.print_debug("Pas de construction ..., pas de palais ...")
		Global.print_debug("Pas de palais ..., pas de palais.")

func init_data():
	# for point in terrain.get_points():
		# point.set_elevation(point_find_elevation(point.point2d()))
		# point.set_data("water", point_is_water(point))
		# point.set_data("mountain", point_is_mountain(point))
		# point.set_data("river", point_is_river(point))

	# fill_oceans()
	
	# for point in terrain.get_points():
	# 	if point.get_data("water") and not point.get_data("ocean"):
	# 		point.set_elevation(0.1)
	# 		point.set_data("water", false)
	# 	point.set_data("coast", point_is_coast(point))
	# 	if point.get_data("river"):
	# 		set_river_path(point)
	var triangles = 0
	for triangle in terrain.get_triangles():
		triangles += 1
		triangle.set_elevation(find_elevation(triangle.center2d()))
		# triangle.set_data("elevation", triangle_find_elevation(triangle))
		triangle.set_data("water", triangle_is_water(triangle))
		if not triangle.get_data("water"):
			if triangle.get_elevation() < 0:
				print(triangle.get_elevation())
		if triangle.is_water():
			triangle.set_elevation(0)
	# 	triangle.set_data("ocean", false)
	# 	for point in triangle.points():
	# 		if point.get_data("ocean"):
	# 			triangle.set_data("ocean", true)
	# for edge in terrain.get_edges():
	# 	edge.set_data("coast", edge_is_coast(edge))
	# 	edge.set_data("river", edge_is_river(edge))
	print(triangles)
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

func set_river_path(point):
	#TODO #2 fix rivers
	var start_elevation = point.get_elevation()
	var waypoints = []
	var stack = []
	stack.append(point.get_index())
	var came_from = {}
	
	while stack.size():
		var current_point_id = stack.pop_front()
		if terrain.get_point(current_point_id).get_elevation() < start_elevation:
			waypoints.append(current_point_id)
			start_elevation = terrain.get_point(current_point_id).get_elevation()
			stack = []
		if terrain.get_point(current_point_id).get_data("ocean"):
			break
		for neighbour in terrain.get_point(current_point_id).points_around():
			if not came_from.has(neighbour.get_index()):
				stack.append(neighbour.get_index())
				came_from[neighbour.get_index()] = current_point_id
				
	var path = []
	for waypoint in waypoints:
		var current = waypoint
		while current != point.get_index(): 
			if not path.has(current):
				path.append(current)
			current = came_from[current]
	
	path.append(point.get_index())
	for index in path:
		terrain.get_point(index).set_data("river", true)
		# terrain.get_point(index).set_data("water", true)

# Point

func find_elevation(point):

	# var border = border_width + rng.randf_range(-20.0, 20.0)
	var elevation = noise.get_noise_2d(point.x / wavelength, point.y / wavelength)
	
	var nx = 2 * point.x / width - 1
	var ny = 2 * point.y / height - 1

	var radius = range_lerp(elevation, -1, 1, 0.8, 1.0)

	var distance = 1 - (1-pow(nx, 2)) * (1-pow(ny,2))
	distance = sqrt(pow(nx, 2) + pow(ny, 2))
	if distance > radius:
		elevation = (elevation - range_lerp(distance, radius, 1.0, 0.0, 1.0))
		
	elevation = max(elevation, -1)
			
	if elevation > 0.1:
		elevation = max(pow((elevation) * 1.2, 1.5), 0.1)
		
	elevation = min(elevation, 1)
		
	elevation = round(elevation * terraces) / terraces
	return elevation
	
func point_is_water(point):
	if (point.get_elevation() < 0):
		return true
	return false

func point_is_mountain(point):
	if (point.get_elevation() >= mountain_height):
		return true
	return false

func point_is_coast(point):
	if not point.get_data("water"):
		for neighbour in point.points_around():
			if neighbour.get_data("ocean"):
				return true
	return false

func point_is_river(point):
	if point.get_data("mountain") and not point.get_data("river"):
		var random = rng.randi_range(1, river_proba)
		if random == 1:
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
	if triangle.get_elevation() <= 0.0:
		return true
	return false

# Edge

func edge_is_coast(edge):
	if edge.start().get_data("coast") and edge.end().get_data("coast") and edge.triangle().get_data("ocean"):
		return true
	return false

func edge_is_river(edge):
	if edge.start().get_data("river") and edge.end().get_data("river"):
		return true
	return false

func add_trees():
	rng.randomize()
	var treescene = load("res://entities/environment/birchtree/birchtree.tscn")
	for triangle in terrain.get_triangles():
		if not triangle.get_data("water"):
			var num = rng.randi_range(0, 5)
			if num == 1:
				var tree = treescene.instance()
				tree.translation = Vector3(triangle.center3d() * Vector3(1, 12*10, 1))
				add_child(tree)
