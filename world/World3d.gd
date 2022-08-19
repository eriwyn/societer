extends Spatial

var terrain

func _ready():
	pass


func draw_world():
	# for i in range(0, 1, 1):
	# 	print(i)
	var st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# st.add_smooth_group(true)
	for triangle in terrain.get_triangles():
		var factor = Vector3(1, 12*10, 1)
		for edge in triangle.edges():
			if triangle.get_elevation() > edge.opposite_triangle().get_elevation():
				st.add_vertex(Vector3(edge.start().point3d().x, triangle.get_elevation(), edge.start().point3d().z) * factor)
				st.add_vertex(Vector3(edge.end().point3d().x, triangle.get_elevation(), edge.end().point3d().z) * factor)
				st.add_vertex(Vector3(edge.start().point3d().x, edge.opposite_triangle().get_elevation(), edge.start().point3d().z) * factor)
				
				st.add_vertex(Vector3(edge.end().point3d().x, triangle.get_elevation(), edge.end().point3d().z) * factor)
				st.add_vertex(Vector3(edge.end().point3d().x, edge.opposite_triangle().get_elevation(), edge.end().point3d().z) * factor)
				st.add_vertex(Vector3(edge.start().point3d().x, edge.opposite_triangle().get_elevation(), edge.start().point3d().z) * factor)
					
		for point in triangle.points():
			st.add_vertex(Vector3(point.point3d().x, triangle.get_elevation(), point.point3d().z) * factor)

	st.generate_normals()
#	st.generate_tangents()
	st.index()
	# Commit to a mesh.
	var mesh = st.commit()
	
	var mi = MeshInstance.new()
	mi.mesh = mesh
	var material = load("res://world/world.material")
	mi.set_surface_material(0, material)
	mi.create_trimesh_collision()
	mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
	print(mi)
	add_child(mi)
	Global.print_debug(OS.get_ticks_msec() / 1000.0)

func _on_Game_world_loaded(game_terrain):
	terrain = game_terrain
	draw_world()

# 18 - 42
# 4 - 9
