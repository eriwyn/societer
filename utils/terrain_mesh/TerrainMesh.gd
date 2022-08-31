extends ArrayMesh
class_name TerrainMesh

var loader

func create_mesh():
	var vertices = []
	var normals = []
	var uvs = []
	
	var factor = Vector3(1, 120, 1)
	Global.loadings["world_creation"].new_phase("Construction du modele 3d...", Global.terrain.get_centers().size())

	for center in Global.terrain.get_centers():
		# Global.loadings["world_creation"].increment_step()


		if not center.get_data("water"):
			var material_id = Global.materials[center.get_data("material")]
			var top_uv = Vector2(0, float(material_id) / (Global.materials.size()-1))
			var border_uv = Vector2(1, float(material_id) / (Global.materials.size()-1))
			var corner_number =  center.corner_count()
			for corner_count in corner_number:
				var current_corner = center.corner(corner_count)
				var next_corner
				if corner_count < corner_number - 1:
					next_corner = center.corner(corner_count + 1)
				else:
					next_corner = center.corner(0)

				for i in 3:
					normals.append(Vector3.UP)
					uvs.append(top_uv)

				vertices.append(Vector3(current_corner.point2d().x, center.get_elevation(), current_corner.point2d().y) * factor)
				vertices.append(Vector3(next_corner.point2d().x, center.get_elevation(), next_corner.point2d().y) * factor)
				vertices.append(Vector3(center.point2d().x, center.get_elevation(), center.point2d().y) * factor)
			for edge in center.borders():
				if edge.end_center().get_elevation() < edge.start_center().get_elevation():
					var top = edge.start_center().get_elevation()
					var bottom = edge.end_center().get_elevation()
					if edge.end_center().get_data("ocean"):
						bottom = 0.0

					var a = Vector3(edge.start_corner().point3d().x, bottom, edge.start_corner().point3d().z) * factor
					var b = Vector3(edge.end_corner().point3d().x, top, edge.end_corner().point3d().z) * factor
					var c = Vector3(edge.start_corner().point3d().x, top, edge.start_corner().point3d().z) * factor
					var d = Vector3(edge.end_corner().point3d().x, bottom, edge.end_corner().point3d().z) * factor
					var normal = get_triangle_normal(a, b, c)
					for i in 6:
						normals.append(normal)
						uvs.append(border_uv)
					vertices.append(a)
					vertices.append(b)
					vertices.append(c)
					
					vertices.append(a)
					vertices.append(d)
					vertices.append(b)
		Global.loadings["world_creation"].increment_step()


	var array_mesh = []
	array_mesh.resize(Mesh.ARRAY_MAX)
	array_mesh[Mesh.ARRAY_VERTEX] = PoolVector3Array(vertices)
	array_mesh[Mesh.ARRAY_NORMAL] = PoolVector3Array(normals)
	array_mesh[Mesh.ARRAY_TEX_UV] = PoolVector2Array(uvs)

	# var terrain_mesh = TerrainMesh.new()
	var mesh = ArrayMesh.new()

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array_mesh)
	mesh.surface_set_material(0, load("res://world/materials/world.material"))

	save_mesh(array_mesh)
	return array_mesh

func get_triangle_normal(a, b, c):
	# find the surface normal given 3 vertices
	var side1 = b - a
	var side2 = c - a
	var normal = side1.cross(side2)
	return normal

func save_mesh(array_mesh):
	var directory = Directory.new()
	Global.print_debug("Save mesh : %s" %(Global.terrain_name))
	
	# Goto terrain directory
	directory.open("user://")
	if not directory.dir_exists("terrain"):
		directory.make_dir("terrain")
	directory.change_dir("terrain")
	if not directory.dir_exists(Global.terrain_name):
		directory.make_dir(Global.terrain_name)
	directory.change_dir(Global.terrain_name)

	var file = File.new()
	var file_name = "user://terrain/%s/mesh.save" % (Global.terrain_name)
	file.open(file_name, File.WRITE)
	file.store_var(array_mesh)
	file.close()

func load_mesh():
	var file = File.new()
	var file_name = "user://terrain/%s/mesh.save" % (Global.terrain_name)
	Global.print_debug("Load mesh file : %s" % (file_name))
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		var array_mesh = file.get_var()
		file.close()
		return array_mesh
	else:
		Global.print_debug("The mesh file : %s does not exist" % (file_name))
