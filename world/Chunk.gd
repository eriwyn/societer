extends Spatial
class_name Chunk

var noise
var should_remove = true
var x
var z
var empty = true

func _init(x, z):
	self.x = x
	self.z = z

func _ready():
	# generate_chunk()
	generate_grass()
	pass

func generate_grass():
	var poisson_disc_sampling: PoissonDiscSampling = PoissonDiscSampling.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var coords = []
	for center in Global.terrain.get_chunk(Vector2(x, z)):
		if (
			not center.get_data("mountain")
			and not center.get_data("water")
			and not center.get_data("coast")
		):
			var points = poisson_disc_sampling.generate_points(0.1, center.polygon(), 2)
			var points3d = []
			for point in points:
				points3d.append(Vector3(point.x, center.get_elevation() * 120, point.y))
			coords += points3d
	# var multimesh = MultiMesh.new()
	var multimesh = MultiMesh.new()
	multimesh.mesh = load("res://world/grass.obj")
	multimesh.mesh.surface_set_material(0, load("res://world/materials/wind_grass.tres"))
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = coords.size()
	for instance_index in multimesh.instance_count:

		var transform := Transform().rotated(Vector3.UP, rng.randf_range(-PI / 2, PI / 2))
		transform.origin = Vector3(coords[instance_index].x, coords[instance_index].y, coords[instance_index].z)
#		transform.scaled(Vector3())
		
		multimesh.set_instance_transform(instance_index, transform)
	var multimesh_instance = MultiMeshInstance.new()
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)
	pass

func generate_chunk():
	var file = File.new()
	file.open("res://world/materials/materials.json", File.READ)
	var materials = JSON.parse(file.get_as_text()).result

	var st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var factor = Vector3(1, 120, 1)
	# print(x)
	# print(z)
	for center in Global.terrain.get_chunk(Vector2(x, z)):
		# print(center.get_data("water"))
		if not center.get_data("water"):
			empty = false
			# print(center.get_data("material"))
			var material_id = materials[center.get_data("material")]
			var top_uv = Vector2(0, float(material_id) / (materials.size()-1))
			var border_uv = Vector2(1, float(material_id) / (materials.size()-1))

			for edge in center.borders():
				if edge.end_center().get_elevation() < edge.start_center().get_elevation():
					var top = edge.start_center().get_elevation()
					# if edge.start_center().get_data("ocean"):
						# top = -1.0
					var bottom = edge.end_center().get_elevation()
					if edge.end_center().get_data("ocean"):
						bottom = 0.0
					st.add_uv(border_uv)
					st.add_vertex(Vector3(edge.start_corner().point3d().x, bottom, edge.start_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.end_corner().point3d().x, top, edge.end_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.start_corner().point3d().x, top, edge.start_corner().point3d().z) * factor)
					
					st.add_vertex(Vector3(edge.start_corner().point3d().x, bottom, edge.start_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.end_corner().point3d().x, bottom, edge.end_corner().point3d().z) * factor)
					st.add_vertex(Vector3(edge.end_corner().point3d().x, top, edge.end_corner().point3d().z) * factor)

			for corner_count in center.corners().size():
				var current_corner = center.corners()[corner_count]
				var next_corner
				if corner_count < center.corners().size() - 1:
					next_corner = center.corners()[corner_count+1]
				else:
					next_corner = center.corners()[0]

				st.add_uv(Vector2(top_uv))
				st.add_vertex(Vector3(current_corner.point2d().x, center.get_elevation(), current_corner.point2d().y) * factor)
				st.add_vertex(Vector3(next_corner.point2d().x, center.get_elevation(), next_corner.point2d().y) * factor)
				st.add_vertex(Vector3(center.point2d().x, center.get_elevation(), center.point2d().y) * factor)

	if not empty:
		st.generate_normals()
		st.index()

		var mi = MeshInstance.new()
		mi.mesh = st.commit()
		var material = load("res://world/materials/world.material")
		mi.set_surface_material(0, material)
		mi.create_trimesh_collision()
		mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON
		add_child(mi)
