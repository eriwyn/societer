extends Reference

class_name WorldGeneration

export(int) var width = 2048
export(int) var height = 2048
export(int) var spacing = 20
export(int, 1, 9) var octaves = 5
export(int, 1, 30) var wavelength = 8
export(int) var border_width = 200
export(int) var terraces = 30
export(int) var terrace_height = 5
export(float) var mountain_height = 6.0 / 24.0
export(int) var river_proba = 200

var rng = RandomNumberGenerator.new()
var noise = OpenSimplexNoise.new()

func _init():
	Global.loading.reset()
	rng.randomize()
	noise.seed = rng.randi()
	noise.octaves = octaves
	
	if Global.terrain.exists(Global.terrain_name):
		Global.terrain.load(Global.terrain_name)
	else:
		Global.terrain.create(width,height,spacing,Global.terrain_name)
	
	var max_step = (
		# Global.terrain.get_triangles().size()
		Global.terrain.get_points().size()
	)

	if Global.terrain.is_created():
		max_step += Global.terrain.get_points().size()
		max_step += Global.terrain.get_centers().size()
		Global.loading.set_step(Global.terrain.get_points().size())

	Global.loading.set_max_step(max_step)

	if Global.terrain.is_created():
		init_data()
		Global.terrain.save()
		
	if Global.terrain.is_created() or Global.terrain.is_loaded():
		# create_map()
		Global.terrain.set_data("mesh", create_mesh())
		# add_trees()
		# get_tree().change_scene("res://world/game.tscn")
	else:
		Global.print_debug("Pas de Global.terrain, pas de construction ...")
		Global.print_debug("Pas de construction ..., pas de palais ...")
		Global.print_debug("Pas de palais ..., pas de palais.")

	Global.loading.set_end_time()

func init_data():
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
	for center in Global.terrain.get_centers():
		center.set_elevation(find_elevation(center.point2d()))
		if center.get_elevation() <= 0:
			center.set_data("water", true)
		# print(center.get_elevation())
		Global.loading.increment_step()
	# print(Global.terrain.get_centers().size())

	print("first center : %f" % Global.terrain.get_centers()[0])
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

func fill_oceans():
	var stack = []
	for point in Global.terrain.get_points():
		if point.point2d().x < 10 and point.get_data("water") and not point.get_data("ocean"):
			stack.append(point.get_index())
			while stack.size():
				var current_point_id = stack.pop_back()
				Global.terrain.get_point(current_point_id).set_data("ocean", true)
				for neighbour in Global.terrain.get_point(current_point_id).points_around():
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

# func add_trees():
# 	rng.randomize()
# 	var treescene = load("res://entities/environment/birchtree/birchtree.tscn")
# 	for triangle in Global.terrain.get_triangles():
# 		if not triangle.get_data("water"):
# 			var num = rng.randi_range(0, 5)
# 			if num == 1:
# 				var tree = treescene.instance()
# 				tree.translation = Vector3(triangle.center3d() * Vector3(1, 12*10, 1))
# 				add_child(tree)

func create_mesh():
	var st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# for triangle in Global.terrain.get_triangles():
	# 	if not triangle.is_water():
	# 		if triangle.get_elevation() < 0:
	# 			print(triangle.get_elevation())
	# 		var factor = Vector3(1, 120, 1)
	# 		for edge in triangle.edges():
	# 			if triangle.get_elevation() > edge.opposite_triangle().get_elevation():
	# 				st.add_vertex(Vector3(edge.start().point3d().x, triangle.get_elevation(), edge.start().point3d().z) * factor)
	# 				st.add_vertex(Vector3(edge.end().point3d().x, triangle.get_elevation(), edge.end().point3d().z) * factor)
	# 				st.add_vertex(Vector3(edge.start().point3d().x, edge.opposite_triangle().get_elevation(), edge.start().point3d().z) * factor)
					
	# 				st.add_vertex(Vector3(edge.end().point3d().x, triangle.get_elevation(), edge.end().point3d().z) * factor)
	# 				st.add_vertex(Vector3(edge.end().point3d().x, edge.opposite_triangle().get_elevation(), edge.end().point3d().z) * factor)
	# 				st.add_vertex(Vector3(edge.start().point3d().x, edge.opposite_triangle().get_elevation(), edge.start().point3d().z) * factor)
						
	# 		for point in triangle.points():
	# 			st.add_vertex(Vector3(point.point3d().x, triangle.get_elevation(), point.point3d().z) * factor)
	# 	Global.loading.increment_step()


	var factor = Vector3(1, 120, 1)
	for center in Global.terrain.get_centers():
		if not center.get_data("water"):
			for edge in center.borders():
				if edge.end_center().get_elevation() < edge.start_center().get_elevation():
					st.add_vertex(Vector3(edge.start_corner().point3d().x, edge.end_center().get_elevation(), edge.start_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.end_corner().point3d().x, edge.start_center().get_elevation(), edge.end_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.start_corner().point3d().x, edge.start_center().get_elevation(), edge.start_corner().point3d().z) * factor)
					
					st.add_vertex(Vector3(edge.start_corner().point3d().x, edge.end_center().get_elevation(), edge.start_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.end_corner().point3d().x, edge.end_center().get_elevation(), edge.end_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.end_corner().point3d().x, edge.start_center().get_elevation(), edge.end_corner().point3d().z) * factor)
						
			for corner_count in center.corners().size():
				var current_corner = center.corners()[corner_count]
				var next_corner
				if corner_count < center.corners().size() - 1:
					next_corner = center.corners()[corner_count+1]
				else:
					next_corner = center.corners()[0]

				st.add_vertex(Vector3(current_corner.point2d().x, center.get_elevation(), current_corner.point2d().y) * factor)
				st.add_vertex(Vector3(next_corner.point2d().x, center.get_elevation(), next_corner.point2d().y) * factor)
				st.add_vertex(Vector3(center.point2d().x, center.get_elevation(), center.point2d().y) * factor)
		Global.loading.increment_step()

	st.generate_normals()
	st.index()

	var mi = MeshInstance.new()
	mi.mesh = st.commit()
	var material = load("res://world/world.material")
	mi.set_surface_material(0, material)
	mi.create_convex_collision()
	mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
	return mi

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
