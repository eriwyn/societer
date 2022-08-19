extends Reference

# Build terrain from delaunay graph
class_name Terrain

# Triangles iterator
class Triangles:
	var _terrain
	var _curr
	var _end

	func _init(terrain):
		self._terrain = terrain
		self._curr = 0
		self._end = _terrain._triangles.size() / 3
		
	func _should_continue():
		return (_curr < _end)
		
	func _iter_init(_arg):
		_curr = 0
		return _should_continue()
		
	func _iter_next(_arg):
		_curr += 1
		return _should_continue()
		
	func _iter_get(_arg):
		var triangle = Triangle.new(_curr,_terrain)
		return triangle
		
	func size():
		return _end

# Triangle object
class Triangle:
	var _idx
	var _terrain
	
	func _init(idx, terrain):
		self._idx = idx
		self._terrain = terrain
		
	func get_index():
		return _idx
		
	func has_key(key):
		return _terrain._triangles_data[_idx].has(key)
		
	func set_data(key,value):
		var data = _terrain._triangles_data[_idx]
		data[key] = value
		
	func get_data(key):
		var data = _terrain._triangles_data[_idx]
		if data.has(key):
			return data[key]
		
	func edges():
		return [Edge.new(3 * _idx, _terrain), Edge.new(3 * _idx + 1, _terrain), Edge.new(3 * _idx + 2, _terrain)]
		
	func points():
		var list_points = []
		for edge in edges():
			list_points.append(Point.new(_terrain._triangles[edge._idx], _terrain))
		return list_points
		
	func triangles_adjacent():
		var list_triangles = []
		for edge in edges():
			var opposite = Edge.new(_terrain._halfedges[edge._idx], _terrain)
			if opposite._idx >= 0:
				list_triangles.append(opposite.triangle())
		return list_triangles
		
	func center2d():
		var points = points()
		return (points[0].point2d() + points[1].point2d() + points[2].point2d()) / 3.0
		
	func center3d():
		var points = points()
		return (points[0].point3d() + points[1].point3d() + points[2].point3d()) / 3.0
		
	func polygon():
		var polygon = []
		for point in points():
			polygon.append(point.point2d())
		return polygon

# Points iterator		
class Points:
	var _terrain
	var _curr
	var _end
	
	func _init(terrain):
		self._terrain = terrain
		self._curr = 0
		self._end = _terrain._points.size()
		
	func _should_continue():
		return (_curr < _end)
		
	func _iter_init(_arg):
		_curr = 0
		return _should_continue()
		
	func _iter_next(_arg):
		_curr += 1
		return _should_continue()
		
	func _iter_get(_arg):
		var point = Point.new(_curr,_terrain)
		return point
		
	func size():
		return _end

# Point object	
class Point:
	var _idx
	var _terrain
	
	func _init(idx, terrain):
		self._idx = idx
		self._terrain = terrain
		
	func get_index():
		return _idx

	func has_key(key):
		return _terrain._points_data[_idx].has(key)
				
	func set_data(key,value):
		var data = _terrain._points_data[_idx]
		data[key] = value
		
	func get_data(key):
		var data = _terrain._points_data[_idx]
		if data.has(key):
			return data[key]
		
	func point3d():
		return _terrain._points[_idx]
		
	func point2d():
		var point3d:Vector3 = _terrain._points[_idx]
		var point2d:Vector2 = Vector2(point3d.x, point3d.z)
		return(point2d)
		
	func set_elevation(elevation:float):
		_terrain._points[_idx].y = elevation
		
	func get_elevation():
		return(_terrain._points[_idx].y)
		
	func edges_around():
		var list_edges = []
		var incoming_edge = Edge.new(_idx, _terrain)
		var outgoing_edge
		while true:
			list_edges.append(incoming_edge);
			outgoing_edge = incoming_edge.next_half()
			incoming_edge = Edge.new(_terrain._halfedges[outgoing_edge._idx], _terrain);
			if not (incoming_edge._idx != -1 and incoming_edge._idx != _idx):
				break
		return list_edges
		
	func points_around():
		var list_points = []
		var incoming = _terrain._points_to_halfedges.get(_idx)
		var incoming_edge = Edge.new(incoming, _terrain)
		var outgoing_edge
		while true:
			list_points.append(Point.new(_terrain._triangles[incoming_edge._idx], _terrain));
			outgoing_edge = incoming_edge.next_half()
			incoming_edge = Edge.new(_terrain._halfedges[outgoing_edge._idx], _terrain);
			if not (incoming_edge._idx != -1 and incoming_edge._idx != incoming):
				break
		return list_points

# Edges iterator
class Edges:
	var _terrain
	var _curr
	var _end
	
	func _init(terrain):
		self._terrain = terrain
		self._curr = 0
		self._end = _terrain._triangles.size()
		
	func _should_continue():
		return (_curr < _end)
		
	func _iter_init(_arg):
		_curr = 0
		return _should_continue()
		
	func _iter_next(_arg):
		_curr += 1
		return _should_continue()
		
	func _iter_get(_arg):
		var edge = Edge.new(_curr,_terrain)
		return edge
		
	func size():
		return _end
		
# Edge object
class Edge:
	var _idx
	var _terrain
	
	func _init(idx, terrain):
		self._idx = idx
		self._terrain = terrain
		
	func get_index():
		return _idx

	func has_key(key):
		return _terrain._edges_data[_idx].has(key)
				
	func set_data(key,value):
		_terrain._edges_data[_idx][key] = value
		
	func get_data(key):
		var data = _terrain._edges_data[_idx]
		if data.has(key):
			return data[key]
		
	func next_half():
		return Edge.new(_idx - 2 if _idx % 3 == 2 else _idx + 1, _terrain)

	func prev_half():
		return Edge.new(_idx + 2 if _idx % 3 == 0 else _idx -1, _terrain)
		
	func triangle():
		return Triangle.new(floor(_idx / 3), _terrain)
		
	func start():
		return Point.new(_terrain._triangles[_idx], _terrain)
		
	func end():
		return Point.new(_terrain._triangles[next_half()._idx], _terrain)
	
	func opposite():
		return Edge.new(_terrain._halfedges[_idx], _terrain)
	
	func line():
		var line = []
		line.append(start().point2d())
		line.append(end().point2d())
		return line

# Terrain instance variables

var _width: int
var _height: int
var _spacing: int
var _name: String
var _points = PoolVector3Array()
var _halfedges
var _triangles
var _points_to_halfedges = {}
var _data = {}
var _points_data = []
var _edges_data = []
var _triangles_data = []

var _created = false
var _loaded = false
var _path = ""
var _list = []

# Terrain constructor
func _init(width:int=1600, height:int=800, spacing:int=30, create=false, name:String=""):
	var directory = Directory.new()
	var file = File.new()
	var file_name = ""
	var directory_name = ""
	var path = ""
	var parameter = {}
	var parameter_file_name = ""
	var graph_file_name = ""
	var data_file_name = ""
	
	# Get list terrain
	directory.open("user://")
	if not directory.dir_exists("terrain"):
		directory.make_dir("terrain")
	directory.change_dir("terrain")
	directory.list_dir_begin()
	directory_name = directory.get_next()
	while directory_name != "":
		if directory.dir_exists(directory_name):
			# Ok terrain path found
			path = "user://terrain/%s" % (directory_name)
			
			# Get terrain parameters
			file_name = "%s/param.save" % path
			if file.file_exists(file_name):
				parameter = {}
				file.open(file_name, File.READ)
				parameter["width"] = file.get_var()
				parameter["height"] = file.get_var()
				parameter["spacing"] = file.get_var()
				parameter["name"] = file.get_var()
				file.close()
				_list.append(parameter)
		directory_name = directory.get_next()
	directory.list_dir_end()
	
	# Create or Load Terrain
	_path = "user://terrain/%s" % (name)
	parameter_file_name = "%s/param.save" % (_path)
	graph_file_name = "%s/graph.save" % (_path)
	data_file_name = "%s/data.save" % (_path)
	if directory.open(_path) == OK and file.file_exists(parameter_file_name) and file.file_exists(graph_file_name) and file.file_exists(data_file_name) and not create:
		Global.print_debug("loading : %s ..." % (name))
		load(name)
	else:
		if name:
			create(width, height, spacing, name)
		
func create(width:int, height:int, spacing:int, name:String):
	Global.print_debug("Creating : %s ..." % (name))
	var delaunay: Delaunator
	_width = width
	_height = height
	_spacing = spacing
	_name = name
	_create_points()
	delaunay = Delaunator.new(_points)
	
	_halfedges = PoolIntArray(delaunay.halfedges)
	_triangles = PoolIntArray(delaunay.triangles)
	
	# Initialize _points_to_halfedges
	for edge in get_edges():
		var endpoint = _triangles[edge.next_half().get_index()]
		if (! _points_to_halfedges.has(endpoint) or _halfedges[edge.get_index()] == -1):
			_points_to_halfedges[endpoint] = edge.get_index()
		
	# Initialise _points_data
	for point_idx in self.get_points().size():
		_points_data.append({})
	
	# Initialise _edges_data
	for edge_idx in self.get_edges().size():
		_edges_data.append({})
	
	# Initialise _triangle_data
	for triangle_idx in self.get_triangles().size():
		_triangles_data.append({})
	
	_created = true
	save()

# Create points on the terrain	
func _create_points():
	var rect = Rect2(Vector2(0, 0), Vector2(_width, _height))
	var poisson_disc_sampling: PoissonDiscSampling = PoissonDiscSampling.new()
	var points2d = poisson_disc_sampling.generate_points(_spacing, rect, 5)
	_points.resize(points2d.size())
	for point_idx in points2d.size():
		_points[point_idx].x = points2d[point_idx].x
		_points[point_idx].z = points2d[point_idx].y
	
# Terrain methodes
func get_triangles():
	var triangles = Triangles.new(self)
	return triangles
	
func get_edges():
	var edges = Edges.new(self)
	return edges

func get_points():
	var points = Points.new(self)
	return points
	
func get_point(idx):
	return Point.new(idx, self)
	
func get_edge(idx):
	return Edge.new(idx, self)
	
func get_triangle(idx):
	return Triangle.new(idx, self)
	
func save():
	var directory = Directory.new()
	Global.print_debug("Save terrain : %s" %(_name))
	
	# Goto terrain directory
	directory.open("user://")
	if not directory.dir_exists("terrain"):
		directory.make_dir("terrain")
	directory.change_dir("terrain")
	if not directory.dir_exists(_name):
		directory.make_dir(_name)
	directory.change_dir(_name)
	
	# Save terrain
	save_parameter()
	save_graph()
	save_data()

func save_parameter():
	var file = File.new()
	var file_name = "user://terrain/%s/param.save" % (_name)
	Global.print_debug("Save parameter terrain : %s" % (_name))
	file.open(file_name, File.WRITE)
	file.store_var(_width)
	file.store_var(_height)
	file.store_var(_spacing)
	file.store_var(_name)
	file.close()
	
func save_graph():
	var file = File.new()
	var file_name = "user://terrain/%s/graph.save" % (_name)
	Global.print_debug("Save graph terrain : %s" % (_name))
	file.open(file_name, File.WRITE)
	file.store_var(_points)
	file.store_var(_halfedges)
	file.store_var(_triangles)
	file.store_var(_points_to_halfedges)
	file.close()
	
func save_data():
	var file = File.new()
	var file_name = "user://terrain/%s/data.save" % (_name)
	Global.print_debug("Save data terrain : %s" % (_name))
	file.open(file_name, File.WRITE)
	file.store_var(_data)
	file.store_var(_points_data)
	file.store_var(_edges_data)
	file.store_var(_triangles_data)
	file.close()
	
func load(name):
	# Goto terrain directory
	var directory = Directory.new()
	directory.open("user://")
	if not directory.dir_exists("terrain"):
		directory.make_dir("terrain")
	directory.change_dir("terrain")
	if not directory.dir_exists(name):
		directory.make_dir(name)
	directory.change_dir(name)
	
	# Load parameter
	if directory.file_exists("param.save"):
		load_parameter(name)
		
	# Load graph
	if directory.file_exists("graph.save"):
		load_graph(name)
		
	# Load data
	if directory.file_exists("data.save"):
		load_data(name)
		
	_loaded = true

func load_parameter(name):
	var file = File.new()
	var file_name = "user://terrain/%s/param.save" % (name)
	Global.print_debug("Load parameter file : %s" % (file_name))
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		_width = file.get_var()
		_height = file.get_var()
		_spacing = file.get_var()
		_name = file.get_var()
		file.close()
	else:
		Global.print_debug("The parameter file : %s does not exist" % (file_name))
		
func load_graph(name):
	var file = File.new()
	var file_name = "user://terrain/%s/graph.save" % (name)
	Global.print_debug("Load graph file : %s" % (file_name))
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		_points = file.get_var()
		_halfedges = file.get_var()
		_triangles = file.get_var()
		_points_to_halfedges = file.get_var()
		file.close()
	else:
		Global.print_debug("The graph file : %s does not exist" % (file_name))
		
func load_data(name):
	var file = File.new()
	var file_name = "user://terrain/%s/data.save" % (name)
	Global.print_debug("Load data file : %s" % (file_name))
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		_data = file.get_var()
		_points_data = file.get_var()
		_edges_data = file.get_var()
		_triangles_data = file.get_var()
		file.close()
	else:
		Global.print_debug("The data file : %s does not exist" % (file_name))
	
func list():
	return _list

func is_created():
	return _created
	
func is_loaded():
	return _loaded
	
func exists(name):
	for terrain in _list:
		if name == terrain["name"]:
			return true
	return false
	
func get_triangles_as_polygon():
	var list_polygon = []
	for triangle in get_triangles():
		list_polygon.append(triangle.polygon())
	return list_polygon
	
func get_edges_as_line():
	var list_lines = []
	for edge in get_edges():
		var line = []
		line.append(edge.start().point2d())
		line.append(edge.end().point2d())
		list_lines.append(line)
	return list_lines
	
func get_voronoi_edges_as_line():
	var list_lines = []
	for start_edge in get_edges():
		var line = []
		var end_edge = start_edge.opposite()
		if (start_edge.get_index() < end_edge.get_index()):
			line.append(start_edge.triangle().center2d())
			line.append(end_edge.triangle().center2d())
			list_lines.append(line)
	return list_lines

func get_voronoi_cells_as_polygon():
	var list_polygon = []
	for point in get_points():
		var polygon = []
		for edge in point.edges_around():
			polygon.append(edge.triangle().center2d())
		list_polygon.append(polygon)
	return(list_polygon)
			
