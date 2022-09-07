extends Spatial

var rng = RandomNumberGenerator.new()
var chunk_size = 32
var chunk_amount = 1
var chunks = {}
var unready_chunks = {}
var thread

func _ready():
	add_world()
	thread = Thread.new()
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


func add_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
		
	if not thread.is_active():
		thread.start(self, "load_chunk", [thread, x, z])
		unready_chunks[key] = 1

func load_chunk(array):
	var thread = array[0]
	var x = array[1]
	var z = array[2]

	# print(x)
	# print(z)
	
	var chunk = Chunk.new(x * chunk_size, z * chunk_size)
		
	# chunk.translation = Vector3(x * chunk_size, 0, z * chunk_size)
	
	call_deferred("load_done", chunk, thread)
	
func load_done(chunk, thread):
	add_child(chunk)
	var key = str(chunk.x / chunk_size) + "," + str(chunk.z / chunk_size)
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()
	
func get_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key):
		return chunks.get(key)
		
	return null
	
func _process(delta):
	update_chunks()
	clean_up_chunks()
	reset_chunks()

func update_chunks():
	var camera_translation = $CamBase/Camera.translation
	var c_x = int(camera_translation.x) / chunk_size
	var c_z = int(camera_translation.y) / chunk_size * -1

	var stack = []
	var used = []

	stack.append(Vector2(c_x, c_z))
	while stack.size():
		var current_vector = stack.pop_back()
		used.append(current_vector)
		add_chunk(current_vector.x, current_vector.y)
		var chunk = get_chunk(current_vector.x, current_vector.y)
		if chunk != null:
			chunk.should_remove = false
		
		var neighbours = [
			Vector2(current_vector.x, current_vector.y - 1), # n
			Vector2(current_vector.x + 1, current_vector.y - 1), # n_e
			Vector2(current_vector.x + 1, current_vector.y), # e
			Vector2(current_vector.x + 1, current_vector.y + 1), # s_e
			Vector2(current_vector.x, current_vector.y + 1), # s
			Vector2(current_vector.x - 1, current_vector.y + 1), # s_w
			Vector2(current_vector.x - 1, current_vector.y), # w
			Vector2(current_vector.x - 1, current_vector.y - 1) # n_w
		]

		for neighbour in neighbours:
			if(
				neighbour.x >= c_x - chunk_amount * 0.5
				and neighbour.x <= c_x + chunk_amount * 0.53
				and neighbour.y >= c_z - chunk_amount * 0.5
				and neighbour.y <= c_z + chunk_amount * 0.53
				and not neighbour in used
			):
				stack.append(neighbour)




	
func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks.erase(key)
	
func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
