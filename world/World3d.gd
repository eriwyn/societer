extends Spatial

var rng = RandomNumberGenerator.new()
var chunk_size = 32
var chunk_amount = 16
var chunks = {}
var unready_chunks = {}
var thread

func _ready():
	add_world()
	add_trees()

func add_world():
	var terrain_mesh = TerrainMesh.new()
	terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, Global.terrain.get_temp_data("mesh"))
	terrain_mesh.surface_set_material(0, load("res://world/materials/world.material"))

	var mi := MeshInstance.new()
	mi.mesh = terrain_mesh
	mi.create_trimesh_collision()

	add_child(mi)
	Global.terrain.reset_temp_data()

func add_trees():
	rng.randomize()
	var treescene = load("res://entities/environment/birchtree/birchtree.tscn")
	var poisson_disc_sampling: PoissonDiscSampling = PoissonDiscSampling.new()
	
	for center in Global.terrain.get_centers():
		if not center.get_data("water"):
			var num = rng.randi_range(0,100)
			if center.get_data("forest") or num == 1:
					var points2d = poisson_disc_sampling.generate_points(3, center.polygon(), 2)
					for point in points2d:
						var tree = treescene.instance()
						var scaling = rng.randi_range(0.8, 1.2)
						tree.scale = Vector3(scaling, scaling, scaling)
						tree.rotate_y(rng.randi_range(0, 2*PI))
						tree.translation = Vector3(point.x, center.get_elevation() * 120, point.y)
						add_child(tree)
