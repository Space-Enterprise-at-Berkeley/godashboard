extends Node
class_name Preprocessor

static func get_preprocessor(field: String, preprocessor_data: String) -> Preprocessor:
	var preprocessor_sections: PackedStringArray = preprocessor_data.split(",")
	match preprocessor_sections[0]:
		"filtered": return PreprocessorFilter.new()
		"roc": return PreprocessorROC.new()
		_: return Preprocessor.new()

func process_data(value: Variant, timestamp: int) -> Variant:
	return value

class PreprocessorFilter:
	extends Preprocessor
	
	# I have no clue how this works, but apparently it does. Copied from Sekhar
	var downsample_factor: int = 20
	var downsample_ctr: int = 0
	var downsample_roc: int = 0
	var state: Array[Array] = [[0, 0], [0, 0], [0, 0], [0, 0]]
	var filter_taps: Array[Array] = [
		[3.12389769e-05, 6.24779538e-05, 3.12389769e-05, 1.00000000e+00, -1.72593340e+00, 7.47447372e-01],
		[1.00000000e+00, 2.00000000e+00, 1.00000000e+00, 1.00000000e+00, -1.86380049e+00, 8.87033000e-01]
	] # 2x SOS sections, cutoff 5Hz @ 200Hz sample rate
	
	func process_data(value: Variant, timestamp: int) -> Variant:
		var out: float = value
		for i in filter_taps.size():
			var ft: Array = filter_taps[i]
			var y: float = (ft[0] * out) + state[i][0]
			state[i][0] = (ft[1] * out) - (ft[4] * y) + state[i][1]
			state[i][1] = (ft[2] * out) - (ft[5] * y)
			out = y
		return out

class PreprocessorROC:
	extends PreprocessorFilter
	
	var last: float = 0
	var last_time: float = 0
	
	func process_data(value: Variant, timestamp: int) -> Variant:
		var diff: float = value - last
		var time_diff: float = timestamp - last_time
		var roc: float = diff * 1000.0 / time_diff
		last = value
		last_time = timestamp
		return super.process_data(roc, timestamp)
