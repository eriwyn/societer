extends MultiMeshInstance

var extents = Vector2(10, 10)

func _ready():
	var poisson_disc_sampling: PoissonDiscSampling = PoissonDiscSampling.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var coords = []
	for center in Global.terrain.get_centers():
		if (
			not center.get_data("mountain")
			and not center.get_data("water")
			and not center.get_data("coast")
		):
			var points = poisson_disc_sampling.generate_points(2, center.polygon(), 2)
			var points3d = []
			for point in points:
				points3d.append(Vector3(point.x, center.get_elevation() * 120, point.y))
			coords += points3d
	multimesh.instance_count = coords.size()
	for instance_index in multimesh.instance_count:

		var transform := Transform().rotated(Vector3.UP, rng.randf_range(-PI / 2, PI / 2))
		transform.origin = Vector3(coords[instance_index].x, coords[instance_index].y, coords[instance_index].z)
#		transform.scaled(Vector3())
		
		multimesh.set_instance_transform(instance_index, transform)
