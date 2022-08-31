extends Reference
class_name LoadingHelper

class Phase:
	var _label: String
	var _start_time = 0
	var _end_time = 0
	var is_loading = false
	var is_finished = false
	var _step = 0
	var _max_step = 0

	func _init(label, max_step):
		self._label = label
		self._max_step = max_step
		_start_time = OS.get_ticks_msec()

	func stop():
		_end_time = OS.get_ticks_msec()
		set_step(_max_step)
		is_loading = false
		is_finished = true

	func get_label():
		return _label

	func set_max_step(number: int):
		_max_step = number
		
	func get_max_step():
		return _max_step

	func set_step(number: int):
		_step = number

	func get_step():
		return _step

	func increment_step():
		_step += 1

	func get_start_time():
		return _start_time

	func get_end_time():
		return _end_time

	func get_elapsed_time(unit):
		var elapsed_time = _end_time - _start_time
		if unit == "s":
			elapsed_time = float(elapsed_time) / 1000.0
		
		return elapsed_time

var is_loading = false
var is_finished = false
var _max_phases = 0
var _phases = []
var _coeffs
var _phases_progression = []
var _total_coeffs = 0

func start(coeffs, first_phase_label, first_phase_max_step):
	is_loading = true
	self._max_phases = coeffs.size()
	self._coeffs = coeffs
	for coeff in coeffs:
		self._total_coeffs += coeff
		self._phases_progression.append(self._total_coeffs)
	new_phase(first_phase_label, first_phase_max_step)

func stop():
	is_loading = false
	is_finished = true
	if get_current_phase():
		get_current_phase().stop()

func get_current_phase():
	if _phases.size() > 0:
		return _phases[_phases.size() - 1]
	return null

func new_phase(label: String, max_step: int):
	if get_current_phase():
		get_current_phase().stop()
	_phases.append(Phase.new(label, max_step))

func increment_step():
	_phases[_phases.size() - 1].increment_step()

func get_phases():
	return _phases

func get_start_time():
	return _phases[0].get_start_time()

func get_end_time():
	return get_current_phase().get_end_time()

func get_elapsed_time(unit):
	var elapsed_time = get_end_time() - get_start_time()
	if unit == "s":
		elapsed_time = float(elapsed_time) / 1000.0

	return elapsed_time

func get_percentage():
	var percentage = 0
	if _max_phases > 0:
		var min_progress = float(_phases_progression[_phases.size() - 2]) / float(_total_coeffs) * 100
		var max_progress = float(_phases_progression[_phases.size() - 1]) / float(_total_coeffs) * 100
		var phase_progress = float(get_current_phase().get_step()) / float(get_current_phase().get_max_step())
		
		percentage = range_lerp(phase_progress, 0, 1, min_progress, max_progress)
	return percentage
