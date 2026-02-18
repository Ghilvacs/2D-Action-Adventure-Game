extends Panel

@onready var board_origin: Control = $BoardOrigin

var min_zoom: float = 0.5
var max_zoom: float = 2.0
var zoom_sensitivity: float = 0.1
var is_panning: bool = false


func _ready() -> void:
	await get_tree().process_frame
	
	board_origin.position = size/2
	board_origin.scale = Vector2.ONE


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


func reset_view() -> void:
	board_origin.position = size / 2
	board_origin.scale = Vector2.ONE
