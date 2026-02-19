extends PanelContainer

var my_topic: JournalTopic
var is_expanded: bool = false
var is_moving_mode: bool = false

@onready var button_connect: Button = $MarginContainer/ButtonConnect
@onready var button_remove: Button = $MarginContainer/ButtonRemove
@onready var button_move: Button = $MarginContainer/ButtonMove
@onready var title_label: Label = $MarginContainer/TitleLabel
@onready var entry_list_container: VBoxContainer = $MarginContainer/EntryListContainer


func _ready() -> void:
	button_move.pressed.connect(_on_move_button_pressed)
	button_connect.pressed.connect(_on_connect_button_pressed)


func _process(delta: float) -> void:
	if is_moving_mode:
		var target_position = get_parent().get_local_mouse_position()
		position = target_position - (size / 2)


func _input(event: InputEvent) -> void:
	if is_moving_mode:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			confirm_placement()
			get_viewport().set_input_as_handled()


func setup(topic: JournalTopic) -> void:
	my_topic = topic
	title_label.text = topic.title
	button_remove.pressed.connect(remove_topic_from_board)
	
	var category_color = JournalManager.get_category_board_color(topic.category)
	var style = StyleBoxFlat.new()
	
	style.bg_color = category_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5

	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var board = find_parent("BoardPanel")
		
		if board and board.connection_source_node != null:
			board.finish_connection_attempt(self)
			get_viewport().set_input_as_handled()
			return
		
		toggle_entries()


func remove_topic_from_board() -> void:
	JournalManager.unregister_topic_om_board(my_topic)
	queue_free()


func toggle_entries() -> void:
	is_expanded = !is_expanded
	entry_list_container.visible = is_expanded
	
	if is_expanded:
		populate_entries()


func populate_entries() -> void:
	for child in entry_list_container.get_children():
		child.queue_free()

	var entries = JournalManager.get_entries_for_topic(my_topic)
	
	for entry in entries:
		var label = Label.new()
		label.text = entry.title
		label.custom_minimum_size.x = 100
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_list_container.add_child(label)


func confirm_placement() -> void:
	is_moving_mode = false
	
	if is_expanded:
		entry_list_container.visible = true
		
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP


func _on_move_button_pressed() -> void:
	is_moving_mode = true
	entry_list_container.visible = false
	modulate.a = 0.7
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_connect_button_pressed() -> void:
	var board = find_parent("BoardPanel")
	
	if board:
		if board.connection_source_node == null:
			board.start_connection_attempt(self)
		elif board.connection_source_node != self:
			board.finish_connection_attempt(self)
		else:
			board.finish_connection_attempt(self)
