extends Node2D

var terrain

func heightmap():
	for triangle in terrain.get_triangles():
		var colors = Gradient.new()
		colors.add_point(0.999,  Color("#9e0142")) # red
		colors.add_point(0.5,  Color("#dc865d")) # orange
		colors.add_point(0.25,  Color("#fbf8b0")) # yellow
		colors.add_point(0,  Color("#89cfa5")) # green
		colors.add_point(-0.999,  Color("#5e4fa2")) # blue
		var color = colors.interpolate(min(triangle.get_data("elevation"), 0.999))
		if triangle.get_data("ocean"):
			var factor = pow((triangle.get_data("elevation")+1), 10) / 5.0
			color = Color("#5e4fa2") + Color(factor, factor, factor, 0.0)
		if triangle.polygon().size() > 2:
			draw_polygon(triangle.polygon(), PoolColorArray([color]))

	var coastline = PoolVector2Array()
	for edge in terrain.get_edges():
		if edge.get_data("coast"):
			coastline.append(edge.line()[0])
			coastline.append(edge.line()[1])
		if edge.get_data("river"):
			draw_line(edge.line()[0], edge.line()[1], Color.blue, 5.0)
	draw_multiline(coastline, Color.black)
	
func draw_triangles_edges(color=Color("#000000")):
	for line in terrain.get_edges_as_line():
		draw_line(line[0], line[1], color)
			
func draw_voronoi_edges(color=Color("#000000")):
	for line in terrain.get_voronoi_edges_as_line():
		draw_line(line[0], line[1], color)
			
func draw_voronoi_cells_old():
	var seen = []
	for edge_idx in terrain.edges():
		var triangles = []
		var vertices = []
		var p = terrain._triangles[terrain.next_half_edge(edge_idx)]
		if not seen.has(p):
			seen.append(p)
			var edges = terrain.edges_around_point(edge_idx)
			for edge_around_idx in edges:
				triangles.append(terrain.triangle_of_edge(edge_around_idx))
			for triangle in triangles:
				vertices.append(terrain.triangle_center(triangle))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PoolVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice.x, vertice.z))
				draw_polygon(voronoi_cell, PoolColorArray([color]))
func draw_voronoi_cells():
	for polygon in terrain.get_voronoi_cells_as_polygon():
		var color = Color(randf(), randf(), randf(), 1)
		if polygon.size() > 2:
			draw_polygon(polygon, PoolColorArray([color]))
				
func draw_voronoi_cells_convex_hull():
	for point_idx in terrain.points():
		var triangles = []
		var vertices = []
		var incoming = terrain._points_to_half_edges.get(point_idx)

		if incoming == null:
			triangles.append(0)
		else:
			var edges = terrain.edges_around_point(incoming)
			for edge_idx in edges:
				triangles.append(terrain.triangle_of_edge(edge_idx))

		for triangle_idx in triangles:
			vertices.append(terrain.triangle_center(triangle_idx))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PoolVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))
			draw_polygon(voronoi_cell, PoolColorArray([color]))
	
func _draw():
	print("before drawing")
	heightmap()
#	draw_voronoi_cells()
#	draw_triangles_edges()
	# draw_voronoi_cells_convex_hull()
#	draw_voronoi_edges(Color("#ff0000"))

func _on_Game_world_loaded(game_terrain):
	terrain = game_terrain
	update()
