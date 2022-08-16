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
		
	func _iter_init(arg):
		_curr = 0
		return _should_continue()
		
	func _iter_next(arg):
		_curr += 1
		return _should_continue()
		
	func _iter_get(arg):
		var triangle = Triangle.new(_curr,_terrain)
		return triangle
		
	func size():
		return _end

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
		
	func _iter_init(arg):
		_curr = 0
		return _should_continue()
		
	func _iter_next(arg):
		_curr += 1
		return _should_continue()
		
	func _iter_get(arg):
		var point = Point.new(_curr,_terrain)
		return point
		
	func size():
		return _end
	
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
			outgoing_edge = incoming_edge.opposite()
			incoming_edge = Edge.new(_terrain._halfedges[outgoing_edge._idx], _terrain);
			if not (incoming_edge._idx != -1 and incoming_edge._idx != incoming):
				break
		return list_points

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
		
	func _iter_init(arg):
		_curr = 0
		return _should_continue()
		
	func _iter_next(arg):
		_curr += 1
		return _should_continue()
		
	func _iter_get(arg):
		var edge = Edge.new(_curr,_terrain)
		return edge
		
	func size():
		return _end
		
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
		
const terrain_file = "user://terrain.save"

var width: int
var height: int
var spacing: int
var _points = PoolVector3Array()
var _halfedges
var _triangles
var _points_to_halfedges = {}
var _data = {}
var _points_data = []
var _edges_data = []
var _triangles_data = []
var _file = File.new()
var _debug = true

"""
func general_type_of(obj):
	var typ = typeof(obj)
	var builtin_type_names = ["nil", "bool", "int", "real", "string", "vector2", "rect2", "vector3", "maxtrix32", "plane", "quat", "aabb",  "matrix3", "transform", "color", "image", "nodepath", "rid", null, "inputevent", "dictionary", "array", "rawarray", "intarray", "realarray", "stringarray", "vector2array", "vector3array", "colorarray", "unknown"]

	if(typ == TYPE_OBJECT):
		return obj.type_of()
	else:
		return builtin_type_names[typ]
"""

func _print_debug(message):
	if _debug:
		print(message)

func _init(width:int=1600, height:int=800, spacing:int=30, create=false):
	if _file.file_exists(terrain_file) and not create:
		_print_debug("loading...")
		_load()
	else:
		_print_debug("Creating...")
		var delaunay: Delaunator
		self.width = width
		self.height = height
		self.spacing = spacing
		_create_points()
		delaunay = Delaunator.new(_points)
	
		_halfedges = PoolIntArray(delaunay.halfedges)
		_triangles = PoolIntArray(delaunay.triangles)
	
		# Initialize _points_to_halfedges
		for edge_idx in edges():
			var edge = get_edge(edge_idx)
			var endpoint = _triangles[edge.next_half().get_index()]
			if (! _points_to_halfedges.has(endpoint) or _halfedges[edge_idx] == -1):
				_points_to_halfedges[endpoint] = edge_idx
			
		# Initialise _points_data
		for point_idx in points():
			_points_data.append({})
	
		# Initialise _edges_data
		for edge_idx in edges():
			_edges_data.append({})
	
		# Initialise _triangle_data
		for triangle_idx in triangles():
			_triangles_data.append({})
			
		_save()
	
func _create_points():
	var rect = Rect2(Vector2(0, 0), Vector2(width, height))
	var poisson_disc_sampling: PoissonDiscSampling = PoissonDiscSampling.new()
	var points2d = poisson_disc_sampling.generate_points(spacing, rect, 5)
	_points.resize(points2d.size())
	for point_idx in points2d.size():
		_points[point_idx].x = points2d[point_idx].x
		_points[point_idx].z = points2d[point_idx].y
	
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

func triangles():
	return _triangles.size() / 3
	
func points():
	return _points.size()
	
func edges():
	return _triangles.size()

# Voronoi

func centroid(points):
  return Vector3((points[0].x + points[1].x + points[2].x) / 3.0, 0.0, (points[0].z + points[1].z + points[2].z) / 3.0)

	
func _save():
	_file.open(terrain_file, File.WRITE)
	_file.store_var(width)
	_file.store_var(height)
	_file.store_var(spacing)
	_file.store_var(_points)
	_file.store_var(_halfedges)
	_file.store_var(_triangles)
	_file.store_var(_points_to_halfedges)
	_file.store_var(_points_data)
	_file.store_var(_edges_data)
	_file.store_var(_triangles_data)
	_file.close()
	
func _load():
	_file.open(terrain_file, File.READ)
	width = _file.get_var()
	height = _file.get_var()
	spacing = _file.get_var()
	_points = _file.get_var()
	_halfedges = _file.get_var()
	_triangles = _file.get_var()
	_points_to_halfedges = _file.get_var()
	_points_data = _file.get_var()
	_edges_data = _file.get_var()
	_triangles_data = _file.get_var()
	_file.close()
	
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
			
