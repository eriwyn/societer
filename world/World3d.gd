extends Spatial

var rng = RandomNumberGenerator.new()

func _ready():
	var mi = Global.terrain.get_data("mesh")
	add_child(mi)
	add_trees()

func add_trees():
	rng.randomize()
	var treescene = load("res://entities/environment/birchtree/birchtree.tscn")
	var poisson_disc_sampling: PoissonDiscSampling = PoissonDiscSampling.new()
	
	for center in Global.terrain.get_centers():
		if not center.get_data("water") and not center.get_data("coast") and not center.get_data("mountain"):
			var num = rng.randi_range(0,10)
			if num == 1:
				var points2d = poisson_disc_sampling.generate_points(3, center.polygon(), 2)
				for point in points2d:
					# print(point)
					var tree = treescene.instance()
					var scaling = rng.randi_range(0.8, 1.2)
					tree.scale = Vector3(scaling, scaling, scaling)
					tree.rotate_y(rng.randi_range(0, 2*PI))
					tree.translation = Vector3(point.x, center.get_elevation() * 120, point.y)
					add_child(tree)
