extends Node2D

var terrain

func create_map():
	var river = {"size": 3, "color": "blue"}
	print(terrain)
	print("a")
	terrain.get_edge(16).set_data("river", river)
	
	var triangle_idx = 5
	var triangle = terrain.get_triangle(triangle_idx)
	
	print("Triangle index : %d" % (triangle.get_index()))
	
	var edges = triangle.edges()
	
	print("Number of edges : %d" % (edges.size()))
	print()
	
	for edge in edges:
		print("Edge index : %d" % (edge.get_index()))
		var start_point = edge.start()
		var end_point = edge.end()
		var start = start_point.point2d()
		var end = end_point.point2d()
		
		print("Start point index : %d" % (start_point.get_index()))
		print("End point index : %d" % (end_point.get_index()))

		print("Start point : %s" % (start))
		print("End point : %s" % (end))
		
		if edge.has_key("river"):
			print("Has river")
			var a_river = edge.get_data("river")
			print("River size : %d" % (a_river["size"]))
			print("River color : %s" % (a_river["color"]))
		
		print()
		print(terrain.get_point(5).point3d())
	

func draw_triangles():
	for polygon in terrain.get_triangles_as_polygon():
		var color = Color(randf(), randf(), randf(), 1)
		if polygon.size() > 2:
			draw_polygon(polygon, PoolColorArray([color]))
		
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
	draw_triangles()
#	draw_voronoi_cells()
#	draw_triangles_edges()
	# draw_voronoi_cells_convex_hull()
#	draw_voronoi_edges(Color("#ff0000"))

func _on_Game_world_loaded(game_terrain):
	terrain = game_terrain
	create_map()
