extends Reference

class_name WorldGeneration

export(int) var width = 2048
export(int) var height = 2048
export(int) var spacing = 5
export(int, 1, 9) var octaves = 5
export(int, 1, 30) var wavelength = 8
export(int) var border_width = 200
export(int) var terraces = 100
export(int) var terrace_height = 5
export(float) var mountain_height = 0.3
export(int) var river_proba = 200

var rng = RandomNumberGenerator.new()
var noise = OpenSimplexNoise.new()

func _init():
	rng.randomize()
	noise.seed = rng.randi()
	noise.octaves = octaves
	
	if Global.terrain.exists(Global.terrain_name):
		var coeffs = [1]
		Global.loadings["world_creation"].start(coeffs, "Chargement...", 100)
		Global.terrain.load(Global.terrain_name)
	else:
		var coeffs = [0, 1, 2, 2, 2, 2, 2, 8]
		Global.loadings["world_creation"].start(coeffs, "Start", 100)
		Global.terrain.create(width,height,spacing,Global.terrain_name)

	if Global.terrain.is_created():
		init_data()
		Global.terrain.reset_temp_data()
		Global.terrain.save()
		var terrain_mesh = TerrainMesh.new()
		Global.terrain.set_temp_data("mesh", terrain_mesh.create_mesh())

	if Global.terrain.is_loaded():
		var terrain_mesh = TerrainMesh.new()
		Global.terrain.set_temp_data("mesh", terrain_mesh.load_mesh())
	
	Global.loadings["world_creation"].stop()

func init_data():
	Global.loadings["world_creation"].new_phase("Generation des continents...", Global.terrain.get_centers().size())
	for center in Global.terrain.get_centers():
		center.set_elevation(find_elevation(center.point2d()))
		center.set_data("temperature", find_temperature(center))
		center.set_data("moisture", find_moisture(center.point2d()))
		if center.get_data("temperature") > 0.5:
			center.set_data("snow", true)
		if center.get_elevation() <= 0.0:
			center.set_data("water", true)
		if center.get_elevation() >= mountain_height:
			center.set_data("mountain", true)

		Global.loadings["world_creation"].increment_step()

	Global.loadings["world_creation"].new_phase("Remplissage des oceans...", 1)
	fill_oceans()
	remove_holes()

	Global.loadings["world_creation"].new_phase("Generation des biomes...", Global.terrain.get_centers().size())
	for center in Global.terrain.get_centers():
		center.set_data("coast", is_coast(center.to_point()))
		# if center.get_data("ocean"):
			# center.set_elevation(-1.0)
		
		center.set_data("material", "grass")
		if center.get_data("mountain"):
			center.set_data("material", "stone")
		if center.get_data("coast"):
			center.set_data("material", "sand")
		if (
			not center.get_data("coast") 
			and not center.get_data("mountain")
			and not center.get_data("ocean")
			and center.get_data("moisture") > 0.3
		):
			center.set_data("forest", true)
		Global.loadings["world_creation"].increment_step()


	
	# for point in Global.terrain.get_points():
		# point.set_elevation(point_find_elevation(point.point2d()))
		# point.set_data("water", point_is_water(point))
		# point.set_data("mountain", point_is_mountain(point))
		# point.set_data("river", point_is_river(point))

	# fill_oceans()
	
	# for point in Global.terrain.get_points():
	# 	if point.get_data("water") and not point.get_data("ocean"):
	# 		point.set_elevation(0.1)
	# 		point.set_data("water", false)
	# 	point.set_data("coast", point_is_coast(point))
	# 	if point.get_data("river"):
	# 		set_river_path(point)
	# print("a")
	
	# for center in Global.terrain.get_centers():
	# 	print("z")
	# 	center.set_elevation(find_elevation(center.point2d))
	# 	Global.loading.increment_step()
	# 	print(center.get_elevation())
	# for triangle in Global.terrain.get_triangles():
	# 	triangle.set_elevation(find_elevation(triangle.center2d()))
	# 	# triangle.set_data("elevation", triangle_find_elevation(triangle))
	# 	triangle.set_data("water", triangle_is_water(triangle))
	# 	if not triangle.get_data("water"):
	# 		if triangle.get_elevation() < 0:
	# 			print(triangle.get_elevation())
	# 	if triangle.is_water():
	# 		triangle.set_elevation(0)
	# 	Global.loading.increment_step()
	# 	triangle.set_data("ocean", false)
	# 	for point in triangle.points():
	# 		if point.get_data("ocean"):
	# 			triangle.set_data("ocean", true)
	# for edge in Global.terrain.get_edges():
	# 	edge.set_data("coast", edge_is_coast(edge))
	# 	edge.set_data("river", edge_is_river(edge))



func set_river_path(point):
	#TODO #2 fix rivers
	var start_elevation = point.get_elevation()
	var waypoints = []
	var stack = []
	stack.append(point.get_index())
	var came_from = {}
	
	while stack.size():
		var current_point_id = stack.pop_front()
		if Global.terrain.get_point(current_point_id).get_elevation() < start_elevation:
			waypoints.append(current_point_id)
			start_elevation = Global.terrain.get_point(current_point_id).get_elevation()
			stack = []
		if Global.terrain.get_point(current_point_id).get_data("ocean"):
			break
		for neighbour in Global.terrain.get_point(current_point_id).points_around():
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
		Global.terrain.get_point(index).set_data("river", true)
		# Global.terrain.get_point(index).set_data("water", true)

# Point


	
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











func find_elevation(point):

	# var border = border_width + rng.randf_range(-20.0, 20.0)
	var elevation = noise.get_noise_2d(point.x / wavelength, point.y / wavelength)
	
	var nx = 2 * point.x / width - 1
	var ny = 2 * point.y / height - 1

	var radius = range_lerp(elevation, -1, 1, 0.8, 0.9)

	var distance = 1 - (1-pow(nx, 2)) * (1-pow(ny,2))
	distance = sqrt(pow(nx, 2) + pow(ny, 2))
	if distance > radius:
		elevation = (elevation - range_lerp(distance, radius, 1.0, 0.0, 1.0))
		
	elevation = max(elevation, -1)
			
	if elevation > 0.1:
		elevation = max(pow((elevation) * 1.2, 1.5), 0.1)
		
	elevation = min(elevation, 1)
		
	elevation = (elevation * terraces) / terraces
	return elevation

func find_moisture(point):
	var elevation = noise.get_noise_2d((point.x + 100) / wavelength * 2, (point.y + 100) / wavelength * 2)
	return elevation

func find_temperature(center):
	
	var poles = 4
	var equator = -4
	var elevation = center.get_elevation()
	var latitude = sin(PI * (float(center.point2d().y) / float(Global.terrain.get_parameters()["height"])))
	var temperature = 40*elevation*elevation + poles + (equator-poles) * latitude
	return temperature

func fill_oceans():
	var stack = []
	var first_center = null
	var i = 0.0
	while not first_center:
		first_center = Global.terrain.find_point(Vector2(i, i))
		i += 1.0

	stack.append(first_center.get_index())
	while stack.size():
		var current_point_id = stack.pop_back()
		Global.terrain.get_point(current_point_id).set_data("ocean", true)
		for neighbour in Global.terrain.get_point(current_point_id).points_around():
			if neighbour.get_data("water") and not neighbour.get_data("ocean"):
				stack.append(neighbour.get_index())

func remove_holes():
	for center in Global.terrain.get_centers():
		if center.get_data("water") and not center.get_data("ocean"):
			center.set_elevation(0.02)
			center.set_data("water", false)

func is_coast(point):
	if not point.get_data("water"):
		for neighbour in point.points_around():
			if neighbour.get_data("ocean"):
				return true
	return false




# Enregistrement de la map + intégration dans la génération du monde #32 

# func create_map():
# 	print("oui")
# 	var viewport = Viewport.new()
# 	viewport.size = Vector2(width, height)
# 	var canvas = Node2D.new()
# 	viewport.add_child(canvas)
# 	canvas.draw_line(Vector2(0.0, 0.0), Vector2(1000.0, 1000.0), [Color("#5e4fa2"))
# 	for center in Global.terrain.get_centers():
# 		var colors = Gradient.new()
# 		colors.add_point(0.999,  Color("#9e0142")) # red
# 		colors.add_point(0.5,  Color("#dc865d")) # orange
# 		colors.add_point(0.25,  Color("#fbf8b0")) # yellow
# 		colors.add_point(0.0,  Color("#89cfa5")) # green
# 		colors.add_point(-0.999,  Color("#5e4fa2")) # blue
# 		var color = colors.interpolate(min(center.get_elevation() + 0.001, 0.999))
# 		# color = Color.green
# 		if center.get_data("water"):
# 			# var factor = pow((center.get_elevation()+1.001), 10) / 5.0
# 			color = Color("#5e4fa2")
# 		if center.polygon().size() > 2:
# 			canvas.draw_polygon(center.polygon(), PoolColorArray([color]))
# 		Global.loading.increment_step()

# 	var img = viewport.get_texture().get_data()
# 	img.flip_y()
# 	var err = img.save_png("user://terrain/heightmap.png")
# 	print(err)
# 	# print("non")
