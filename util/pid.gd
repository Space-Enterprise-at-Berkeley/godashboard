extends Node

class PidConnection:
	var from: PidNode
	var to: PidNode
	var pt: PidPressure
	var hasFluid: bool
	
	func _init(from: PidNode, to: PidNode) -> void:
		self.from = from
		self.to = to
		self.hasFluid = false
	
	func set_pt(pt: PidPressure) -> void:
		self.pt = pt

class PidNode:
	var connections: Array[PidConnection]
	var field: String
	
	func _init(connections: Array[PidConnection], field: String) -> void:
		self.connections = connections
		self.field = field
	
	func register_callback() -> void:
		# register callback with field
		return

class NodeSource extends PidNode:
	var pressure: float
	
	func _init(connections: Array[PidConnection], field: String) -> void:
		super(connections, field)
		pressure = 0

class NodeValve extends PidNode:
	var isOpen: bool
	
	func _init(connections: Array[PidConnection], field: String) -> void:
		super(connections, field)
		isOpen = false

class PidPressure:
	var field: String
	var connection: PidConnection
	var pressure: float
	
	func _init(field: String, connection: PidConnection) -> void:
		self.field = field
		self.connection = connection
		self.pressure = 0
	
	func register_callback() -> void:
		# register callback with field
		return

func _ready() -> void:
	var pidConfig: Dictionary = Config.config["pid"]
	
