class_name Pid
extends Node

signal pid_changed

class PidConnection:
	signal connection_changed

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

	func _propagate_connection() -> void:
		for b: String in Pid.connections.keys():
			if Pid.components.connected(id, b):
				Pid.connections[b].hasFluid = hasFluid
		connection_changed.emit()

	func update_connection() -> void:
		var pressure: float
		if pt != null:
			pressure = pt.pressure
		elif from is NodeSource:
			pressure = from.pressure
		elif to is NodeSource:
			pressure = to.pressure
		else:
			return
		var newFluid: bool = pressure >= Pid.AMBIENT_PRESSURE
		if newFluid == hasFluid:
			return
		hasFluid = newFluid
		_propagate_connection()

class PidNode:
	signal node_changed
	
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
		node_changed.emit()
		if connections.size() > 0:
			connections[0].update_connection()

	func register_callback() -> void:
		Databus.register_callback(field, null, _on_source_update)

class NodeValve extends PidNode:
	var isOpen: bool
	
	func _init(init_field: String, state: bool) -> void:
		super(init_field)
		isOpen = state

	func _on_valve_update(value: Variant, timestamp: int) -> void:
		var newOpen: bool = value == 1
		if newOpen == isOpen:
			return
		isOpen = newOpen
		node_changed.emit()
		if isOpen:
			if connections.size() > 0:
				for i in range(connections.size() - 1):
					Pid.components.union(connections[0].id, connections[i+1].id)
				for conn in connections:
					if conn.hasFluid:
						conn._propagate_connection()
						break
		else:
			Pid.recompute()

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
		connection.update_connection()
	
	func register_callback() -> void:
		Databus.register_callback(field, null, _on_pt_update)

class QuickUnion extends RefCounted:
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

static var nodes: Dictionary
static var connections: Dictionary
static var components: QuickUnion
static var AMBIENT_PRESSURE: int

func _ready() -> void:
	# initialize data structures
	var pidConfig: Dictionary = Config.config["pid"]
	nodes = {}
	connections = {}
	AMBIENT_PRESSURE = pidConfig["ambientPressure"]

	# first pass: initialize all the nodes
	for node: Dictionary in pidConfig["nodes"]:
		if node["type"] in ["rbv", "pbv", "manual", "poppet"]:
			var isOpen: bool = node["defaultState"] == "open"
			nodes[node["id"]] = NodeValve.new(node["field"], isOpen)
			nodes[node["id"]].node_changed.connect(func() -> void: pid_changed.emit())
		elif node["type"] in ["tank", "bottle"]:
			nodes[node["id"]] = NodeSource.new(node["field"])
			nodes[node["id"]].node_changed.connect(func() -> void: pid_changed.emit())

	# second pass: initialize all the connections (pipes)
	for conn: Dictionary in pidConfig["connections"]:
		var from: String = conn["from"].left(conn["from"].find("/"))
		var to: String = conn["to"].left(conn["to"].find("/"))
		if !nodes.has(from) || !nodes.has(to):
			GoLogger.error("Connection node id does not exist")
			continue
		connections[conn["id"]] = PidConnection.new(nodes[from], nodes[to], conn["id"])
		connections[conn["id"]].connection_changed.connect(func() -> void: pid_changed.emit())
		nodes[from].add_connection(connections[conn["id"]])
		nodes[to].add_connection(connections[conn["id"]])

	# third pass: initialize all the sensors (PTs)
	for sensor: Dictionary in pidConfig["sensors"]:
		var id: String = sensor["at"]
		if !connections.has(id):
			GoLogger.error("Sensor connection id does not exist")
			continue
		var conn: PidConnection = connections[id]
		conn.set_pt(PidPressure.new(sensor["field"], conn))

	# register callbacks for all nodes and sensors
	for nodeId: String in nodes.keys():
		nodes[nodeId].register_callback()
	for connId: String in connections.keys():
		var conn: PidConnection = connections[connId]
		if conn.pt != null:
			conn.pt.register_callback()

	# initialize quick union with connected components
	recompute()	

static func recompute() -> void:
	# initialize all the connected components
	components = QuickUnion.new()
	for connId: String in connections.keys():
		components.add(connId)
	for node: Dictionary in Config.config["pid"]["nodes"]:
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

	# reset and recalculate hasFluid for each component
	for connId: String in connections.keys():
		connections[connId].hasFluid = false
	for connId: String in connections.keys():
		var conn: PidConnection = connections[connId]
		conn.update_connection()
