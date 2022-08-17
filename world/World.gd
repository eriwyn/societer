extends Spatial

var terrain

func _ready():
	pass


func draw_world():
	var st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_smooth_group(true)
	for triangle in terrain.get_triangles():
		for point in triangle.points():
			st.add_vertex(point.point3d())

	st.generate_normals()
	st.generate_tangents()
	st.index()
	# Commit to a mesh.
	var mesh = st.commit()
	
	var mi = MeshInstance.new()
	mi.mesh = mesh
	var material = load("res://world/world.tres")
	mi.set_surface_material(0, material)
	mi.create_trimesh_collision()
	mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
	print(mi)
	add_child(mi)

func _on_Game_world_loaded(game_terrain):
	terrain = game_terrain
	draw_world()
