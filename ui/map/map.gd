extends Node2D

signal map_clicked

func heightmap():
	draw_rect(Rect2(Vector2(0, 0), Vector2(2048, 2048)), Color("#0e88bd"))
	var coastline = PoolVector2Array()

	for center in Global.terrain.get_centers():
		if not center.get_data("ocean"):
			var colors = Gradient.new()
			colors.add_point(0.999,  Color("#9e0142")) # red
			colors.add_point(0.5,  Color("#dc865d")) # orange
			colors.add_point(0.25,  Color("#fbf8b0")) # yellow
			colors.add_point(0.0,  Color("#89cfa5")) # green
			colors.add_point(-0.999,  Color("#5e4fa2")) # blue
			var color = colors.interpolate(min(center.get_elevation() + 0.001, 0.999))
			# color = Color.green
			if center.get_data("ocean"):
				# var factor = pow((center.get_elevation()+1.001), 10) / 5.0
				color = Color("#5e4fa2")
			if center.get_data("snow"):
				color = Color.white
			# if center.get_data("coast"):
				# color = Color.black
			if center.polygon().size() > 2:
				draw_polygon(center.polygon(), PoolColorArray([color]))

			if center.get_data("coast"):
				for border in center.borders():
					if (border.end_center().get_data("ocean")):
						coastline.append(border.line()[0])
						coastline.append(border.line()[1])
		
	# for edge in Global.terrain.get_edges():
	# 	if edge.get_data("coast"):
			
	# 	if edge.get_data("river"):
	# 		draw_line(edge.line()[0], edge.line()[1], Color.blue, 5.0)
	draw_multiline(coastline, Color.black)
	
func draw_triangles_edges(color=Color("#000000")):
	for line in Global.terrain.get_edges_as_line():
		draw_line(line[0], line[1], color)
			
func draw_voronoi_edges(color=Color("#000000")):
	for line in Global.terrain.get_voronoi_edges_as_line():
		draw_line(line[0], line[1], color)
			
func draw_voronoi_cells_old():
	var seen = []
	for edge_idx in Global.terrain.edges():
		var triangles = []
		var vertices = []
		var p = Global.terrain._triangles[Global.terrain.next_half_edge(edge_idx)]
		if not seen.has(p):
			seen.append(p)
			var edges = Global.terrain.edges_around_point(edge_idx)
			for edge_around_idx in edges:
				triangles.append(Global.terrain.triangle_of_edge(edge_around_idx))
			for triangle in triangles:
				vertices.append(Global.terrain.triangle_center(triangle))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PoolVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice.x, vertice.z))
				draw_polygon(voronoi_cell, PoolColorArray([color]))
func draw_voronoi_cells():
	for polygon in Global.terrain.get_voronoi_cells_as_polygon():
		var color = Color(randf(), randf(), randf(), 1)
		if polygon.size() > 2:
			draw_polygon(polygon, PoolColorArray([color]))
				
func draw_voronoi_cells_convex_hull():
	for point_idx in Global.terrain.points():
		var triangles = []
		var vertices = []
		var incoming = Global.terrain._points_to_half_edges.get(point_idx)

		if incoming == null:
			triangles.append(0)
		else:
			var edges = Global.terrain.edges_around_point(incoming)
			for edge_idx in edges:
				triangles.append(Global.terrain.triangle_of_edge(edge_idx))

		for triangle_idx in triangles:
			vertices.append(Global.terrain.triangle_center(triangle_idx))

		if triangles.size() > 2:
			var color = Color(randf(), randf(), randf(), 1)
			var voronoi_cell = PoolVector2Array()
			for vertice in vertices:
				voronoi_cell.append(Vector2(vertice[0], vertice[1]))
			draw_polygon(voronoi_cell, PoolColorArray([color]))
	
func _draw():
	heightmap()
#	draw_voronoi_cells()
#	draw_triangles_edges()
	# draw_voronoi_cells_convex_hull()
#	draw_voronoi_edges(Color("#ff0000"))

func _process(_delta):
	if Input.is_action_pressed("alt_command"):
		var new_position = get_viewport().get_mouse_position() / scale
		if new_position.x <= 2000 and new_position.y <= 2000:
			emit_signal("map_clicked", new_position)
