extends Node

enum InfluxAction {
	NONE,
	CHECK_HEALTH,
	LIST_DATABASES,
	UPLOAD_POINTS,
}

class InfluxPoint:
	var measurement: String
	var value: Variant
	var timestamp: int
	
	func _init(measurement_p: String, value_p: Variant, timestamp_p: int) -> void:
		measurement = measurement_p
		value = value_p
		timestamp = timestamp_p

class InfluxRequest:
	var action: InfluxAction
	var url: String
	var headers: PackedStringArray
	var method: HTTPClient.Method
	var body: String
	
	func _init(action_p: InfluxAction, url_p: String, headers_p: PackedStringArray, method_p: HTTPClient.Method, body_p: String) -> void:
		action = action_p
		url = url_p
		headers = headers_p
		method = method_p
		body = body_p

var action: InfluxAction = InfluxAction.NONE
var http: HTTPRequest
var request_buffer: Array[InfluxRequest] = []
var host: String = "localhost"
var port: int = 8086
var points_buffer: Array[InfluxPoint] = []
var database: String = "test"
var recording: String = "godashboard_test"

func _ready() -> void:
	http = HTTPRequest.new()
	add_child(http)
	http.timeout = 1.0
	http.request_completed.connect(_response_handler)
	Databus.update.connect(_handle_packet)
	#_check_health()
	#_list_databases()
	_enable_upload_loop()

func _push_request(request: InfluxRequest) -> void:
	request_buffer.append(request)
	if action == InfluxAction.NONE:
		_send_request()

func _send_request() -> void:
	var request: InfluxRequest = request_buffer.pop_front()
	action = request.action
	http.request(request.url, request.headers, request.method, request.body)

func _check_health() -> void:
	_push_request(InfluxRequest.new(InfluxAction.CHECK_HEALTH, "http://%s:%d/health" % [host, port], [], HTTPClient.METHOD_GET, ""))

func _list_databases() -> void:
	_push_request(InfluxRequest.new(InfluxAction.LIST_DATABASES, "http://%s:%d/query?q=SHOW%%20DATABASES" % [host, port], [], HTTPClient.METHOD_GET, ""))

func _upload_points() -> void:
	var body: PackedStringArray = []
	var upload_points_buffer: Array[InfluxPoint] = points_buffer
	points_buffer = []
	for i in upload_points_buffer.size():
		var point: InfluxPoint = upload_points_buffer[i]
		if i != 0:
			body.append("\n")
		body.append(point.measurement)
		body.append(",recording=")
		body.append(recording)
		body.append(" value=")
		match typeof(point.value):
			TYPE_STRING:
				body.append("\"")
				body.append(point.value)
				body.append("\"")
			TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
				body.append(str(point.value))
			_:
				print("Unknown data type for Influx: %d" % typeof(point.value))
		body.append(" ")
		body.append(str(point.timestamp * 1000000))
	_push_request(InfluxRequest.new(InfluxAction.UPLOAD_POINTS, "http://%s:%d/write?db=%s" % [host, port, database], [], HTTPClient.METHOD_POST, "".join(body)))

func _enable_upload_loop() -> void:
	while true:
		_upload_points()
		await get_tree().create_timer(1).timeout

func _response_handler(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		#push_error("Influx moment")
		pass
	else:
		var ascii: String = body.get_string_from_ascii()
		var json: JSON = JSON.new()
		if json.parse(ascii) != OK:
			# push_error("JSON parse error")
			pass
		else:
			var res: Variant = json.data
			match action:
				InfluxAction.CHECK_HEALTH:
					if res["status"] != "pass":
						push_error("Influx health failure")
				InfluxAction.LIST_DATABASES:
					var databases: Array = res["results"][0]["series"][0]["values"].map(func (d: Array) -> String: return d[0]).filter(func (d: String) -> bool: return d != "_internal")
					databases.reverse()
					print(databases)
				InfluxAction.UPLOAD_POINTS:
					pass
					#print(body)
	action = InfluxAction.NONE
	if request_buffer.size() > 0:
		_send_request()

func _handle_packet(fields: Dictionary, timestamp: int) -> void:
	for field: String in fields:
		if fields[field] is float:
			if not is_finite(fields[field]):
				continue
		points_buffer.append(InfluxPoint.new(field, fields[field], timestamp))
