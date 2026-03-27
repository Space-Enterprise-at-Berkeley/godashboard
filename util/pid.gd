extends Node

signal pid_changed

class PidConnection:
	var from: PidNode
	var to: PidNode
	var id: String
	var pt: PidPressure
	var hasFluid: bool
	
	func _init(init_from: PidNode, init_to: PidNode, conn_id: String) -> void:
		self.from = init_from
		self.to = init_to
		self.id = conn_id
		self.hasFluid = false
	
	func set_pt(sensor: PidPressure) -> void:
		self.pt = sensor

class PidNode:
	var connections: Array[PidConnection]
	var field: String
	
	func _init(init_field: String) -> void:
		self.connections = []
		self.field = init_field

	func add_connection(connection: PidConnection) -> void:
		connections.append(connection)
	
	func register_callback() -> void:
		# register callback with field
		return

class NodeSource extends PidNode:
	var pressure: float
	
	func _init(init_field: String) -> void:
		super(init_field)
		pressure = 0

	func _on_source_update(value: Variant, timestamp: int) -> void:
		pressure = value

	func register_callback() -> void:
		Databus.register_callback(field, null, _on_source_update)

class NodeValve extends PidNode:
	var isOpen: bool
	
	func _init(init_field: String, state: bool) -> void:
		super(init_field)
		isOpen = state

	func _on_valve_update(value: Variant, timestamp: int) -> void:
		isOpen = !isOpen

	func register_callback() -> void:
		Databus.register_callback(field, null, _on_valve_update)

class PidPressure:
	var field: String
	var connection: PidConnection
	var pressure: float
	
	func _init(init_field: String, init_connection: PidConnection) -> void:
		self.field = init_field
		self.connection = init_connection
		self.pressure = 0

	func _on_pt_update(value: Variant, timestamp: int) -> void:
		pressure = value
	
	func register_callback() -> void:
		Databus.register_callback(field, null, _on_pt_update)

class QuickUnion:
	var parent: Dictionary

	func _init() -> void:
		parent = {}

	func find_root(node: String) -> String:
		if parent[node] == null:
			return node
		parent[node] = find_root(parent[node])
		return parent[node]

	func add(node: String) -> void:
		parent[node] = null

	func union(a: String, b: String) -> void:
		var root_a: String = find_root(a)
		var root_b: String = find_root(b)
		if root_a != root_b:
			parent[root_a] = root_b

	func connected(a: String, b: String) -> bool:
		var root_a: String = find_root(a)
		var root_b: String = find_root(b)
		return root_a == root_b

var nodes: Dictionary
var connections: Dictionary
var components: QuickUnion

func _ready() -> void:
	# initialize data structures
	var pidConfig: Dictionary = Config.config["pid"]
	nodes = {}
	connections = {}
	components = QuickUnion.new()

	# first pass: initialize all the nodes
	for node in pidConfig["nodes"]:
		if node["type"] in ["rbv", "pbv", "manual", "poppet"]:
			var isOpen: bool = node["defaultState"] == "open"
			nodes[node["id"]] = NodeValve.new(node["field"], isOpen)
		elif node["type"] in ["tank", "bottle"]:
			nodes[node["id"]] = NodeSource.new(node["field"])

	# second pass: initialize all the connections (pipes)
	for conn in pidConfig["connections"]:
		var from: String = conn["from"].left(conn["from"].find("/"))
		var to: String = conn["to"].left(conn["to"].find("/"))
		if !nodes.has(from) || !nodes.has(to):
			GoLogger.error("Connection node id does not exist")
			continue
		connections[conn["id"]] = PidConnection.new(nodes[from], nodes[to], conn["id"])
		nodes[from].add_connection(connections[conn["id"]])
		nodes[to].add_connection(connections[conn["id"]])
		components.add(conn["id"])

	# third pass: initialize all the sensors (PTs)
	for sensor in pidConfig["sensors"]:
		var id: String = sensor["at"]
		if !connections.has(id):
			GoLogger.error("Sensor connection id does not exist")
			continue
		var conn: PidConnection = connections[id]
		conn.set_pt(PidPressure.new(sensor["field"], conn))

	# initialize quick union with connected components
	for node in pidConfig["nodes"]:
		if node["type"] in ["rbv", "pbv", "manual", "poppet"]:
			var valve: NodeValve = nodes[node["id"]]
			if valve.isOpen:
				if valve.connections.size() > 0:
					for i in range(valve.connections.size() - 1):
						components.union(valve.connections[0].id, valve.connections[i+1].id)
		elif node["type"] in ["tank", "bottle"]:
			var source: NodeSource = nodes[node["id"]]
			if source.connections.size() > 0:
				for i in range(source.connections.size() - 1):
					components.union(source.connections[0].id, source.connections[i+1].id)
			
