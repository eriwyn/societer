extends CameraOutline
class_name CameraController

signal camera_moved(new_location)

enum CAMERA_ACTIONS{
	MOVING,
	ROTATING_VIEW,
}

export(float,1,100) var movement_speed = 48
export(float, 100, 10000) var up_speed = 800
export(float,0.01,0.99) var movement_damping = 0.74
export(float,0.01, 3.1415) var max_rotation = 1.2
export(float,0.01, 3.1415) var min_rotation = 0.5

#Value in percentage of screen portion
#A value of 0.3 means that when you place the cursor 30% or less away from an edge it will start pushing the camera
export(float, 0.0,1.0) var edge_size = 0.0

#EDIT HERE--->**,***<--- ZOOM MIN AND MAX LIMITS
export(float, 10,100) var min_zoom = 10
export(float, 10,100) var max_zoom = 100

export(float, 1,3) var zoom_sensibility = 1.4

export(float, 1,3) var rotation_sensibility = 2.3
export(float, 1.0, 10.0) var height = 15.0

var pitch : float
var yaw : float
var current_action = CAMERA_ACTIONS.MOVING
var velocity : Vector3

func _ready():
#	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	pitch = rotation.x
	yaw = rotation.y
	
#	var new_rotation = (max_zoom - fov) * (max_rotation - min_rotation) / max_zoom + min_rotation
	transform.basis = Basis(Vector3(1, 0, 0), (min_rotation + max_rotation) / 2.0)
	fov = (min_zoom + max_zoom) / 2.0

func change_action(action):
	current_action = action
	match(current_action):
#		CAMERA_ACTIONS.MOVING:
#			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		CAMERA_ACTIONS.ROTATING_VIEW:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	
	match(current_action):
		CAMERA_ACTIONS.MOVING:
			#CAMERA MOVEMENT
			velocity.x = clamp(velocity.x * movement_damping,-1.0,1.0)
			velocity.z = clamp(velocity.z * movement_damping,-1.0,1.0)
			
			# get velocity y giver the height of the floor
			var space_state = get_world().direct_space_state
			var result = space_state.intersect_ray(Vector3(global_transform.origin.x, 100, global_transform.origin.z), Vector3(global_transform.origin.x, 0, global_transform.origin.z))
			if result:
				var direction = 0
				var difference = global_transform.origin.y - height - result.position.y
				var vertical = range_lerp(abs(difference),0, 24*5,0.0,1.0)
				if result.position.y > global_transform.origin.y - height:
					direction = 1
				elif result.position.y < global_transform.origin.y - height:
					direction = -1
				velocity.y = vertical * direction

			velocity.y = clamp(velocity.y * movement_damping,-1.0,1.0)

			if velocity != Vector3.ZERO:
				move(velocity)


func change_velocity(_velocity : Vector2):
	velocity.x = _velocity.x
	velocity.z = _velocity.y
	
func move(_velocity : Vector3):
	#Move along cameras X axis
	global_transform.origin += global_transform.basis.x * velocity.x * movement_speed * get_process_delta_time()
	#Move along camera Y axis
	global_transform.origin += global_transform.basis.z * velocity.y * up_speed * get_process_delta_time()
	#Calculate a forward camera direction that is perpendicular to the XZ plane
	var forward = global_transform.basis.x.cross(Vector3.UP)
	#Move the camera along that forward direction
	global_transform.origin += forward * velocity.z * movement_speed * get_process_delta_time()


	emit_signal("camera_moved", global_transform.origin)


func zoom(direction : float):
	#Zooming using fov
	var new_fov = fov + (sign(direction) * pow(abs(direction),zoom_sensibility)/100 * get_process_delta_time())
	fov = clamp(new_fov,min_zoom,max_zoom)

	# Linear equation
	var slope = (min_rotation - max_rotation) / (max_zoom - min_zoom)
	var b = max_rotation - slope * min_zoom
	var new_rotation = slope * fov + b
	transform.basis = Basis(Vector3(1, 0, 0), new_rotation)


func rotate_view(axis : Vector2):
	
	var pitch_rotation_amount = -axis.y/100 * get_process_delta_time() * rotation_sensibility
	var yaw_rotation_amount = -axis.x/100 * get_process_delta_time() * rotation_sensibility
	
	pitch += pitch_rotation_amount
	pitch = clamp(pitch,-PI/2,0)
	
	yaw += yaw_rotation_amount
	
	rotation.x = pitch
	rotation.y = yaw

func teleport(position):
	global_transform.origin.x = position.x
	global_transform.origin.z = position.y

	var y_offset = 0
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(Vector3(global_transform.origin.x, 100, global_transform.origin.z), Vector3(global_transform.origin.x, 0, global_transform.origin.z))
	if result:
		y_offset = result.position.y
	else:
		y_offset = 0
	global_transform.origin.y = height + y_offset

func _on_Map_map_clicked(position):
	teleport(position)


func _on_World_character_created(position):
	teleport(position)
	
