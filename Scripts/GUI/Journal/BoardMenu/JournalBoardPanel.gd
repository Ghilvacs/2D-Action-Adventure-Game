extends Panel

@onready var board_origin: Control = $BoardOrigin
@onready var connections_layer: Control = $BoardOrigin/ConnectionsLayer
@onready var nodes_layer: Control = $BoardOrigin/NodesLayer
@onready var line_drag: Line2D = $BoardOrigin/LineDrag

var min_zoom: float = 0.5
var max_zoom: float = 2.0
var zoom_sensitivity: float = 0.1
var is_panning: bool = false
var connection_source_node: Control = null


func _ready() -> void:
	await get_tree().process_frame

	board_origin.position = size/2
	board_origin.scale = Vector2.ONE


func _process(delta: float) -> void:
	if connection_source_node:
		var start_position = connection_source_node.position + (connection_source_node.size / 2)
		var mouse_position = board_origin.get_local_mouse_position()
		line_drag.points = [start_position, mouse_position]
	
	_update_all_connections()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_panning = true
				mouse_default_cursor_shape = Control.CURSOR_DRAG
			else:
				is_panning = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	if event is InputEventMouseMotion and is_panning:
		board_origin.position += event.relative
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_position(zoom_sensitivity, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_position(-zoom_sensitivity, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and connection_source_node != null:
			cancel_connection_attempt()
			return


func start_connection_attempt(source_node: Control) -> void:
	connection_source_node = source_node
	line_drag.visible = true
	mouse_default_cursor_shape = Control.CURSOR_CROSS


func finish_connection_attempt(target_node: Control) -> void:
	if connection_source_node and target_node and connection_source_node != target_node:
		create_connection(connection_source_node, target_node)
		
	cancel_connection_attempt()


func cancel_connection_attempt() -> void:
	connection_source_node = null
	line_drag.visible = false
	line_drag.points = []
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func create_connection(start_node: Control, end_node: Control) -> void:
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = Color.WHITE
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	connections_layer.add_child(line)
	
	line.set_meta("start_node", start_node)
	line.set_meta("end_node", end_node)
	_update_line_positions(line)


func _update_all_connections() -> void:
	for line in connections_layer.get_children():
		if line is Line2D and line.has_meta("start_node"):
			_update_line_positions(line)


func _update_line_positions(line: Line2D) -> void:
	var start_node = line.get_meta("start_node")
	var end_node = line.get_meta("end_node")
	
	if is_instance_valid(start_node) and is_instance_valid(end_node):
		var start_position = start_node.position + (start_node.size / 2)
		var end_position = end_node.position + (end_node.size / 2)
		line.points = [start_position, end_position]
	else:
		line.queue_free()

func _zoom_at_position(zoom_change: float, mouse_position: Vector2) -> void:
	var old_zoom = board_origin.scale.x
	var new_zoom = clamp(old_zoom + zoom_change, min_zoom, max_zoom)
	
	if old_zoom == new_zoom: return
	
	var mouse_in_local = (mouse_position - board_origin.position) / old_zoom
	board_origin.scale = Vector2(new_zoom, new_zoom)
	board_origin.position = mouse_position - (mouse_in_local * new_zoom)


func add_topic_to_board(topic: JournalTopic, drop_position: Vector2) -> void:
	var local_position = (drop_position - board_origin.position) / board_origin.scale.x
	var node_scene = preload("res://Scenes/GUI/Journal/BoardMenu/TopicBoardNode.tscn").instantiate()
	board_origin.get_node("NodesLayer").add_child(node_scene)
	node_scene.setup(topic)
	node_scene.position = local_position


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("topic")


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		var topic = data["topic"]
		add_topic_to_board(topic, at_position)
		
		if data.has("source_button") and is_instance_valid(data["source_button"]):
			data["source_button"].mark_as_placed()

		JournalManager.register_topic_om_board(topic)
