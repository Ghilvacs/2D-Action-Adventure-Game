class_name DraggableTopicButton extends Button

var topic_data: JournalTopic
var is_placed_on_board: bool = false
var category_color = JournalManager.get_category_color(JournalMenu.current_category)

func _process(delta: float) -> void:
	if is_placed_on_board and JournalMenu.current_view_mode == JournalMenu.ViewMode.BOARD:
		modulate = Color(0.5, 0.5, 0.5, 0.5)
	else:
		modulate = category_color


func _get_drag_data(at_position: Vector2) -> Variant:
	if is_placed_on_board:
		return null
	
	var preview = Label.new()
	preview.text = text
	set_drag_preview(preview)
	
	return {
		"topic": topic_data,
		"source_button": self
	}


func mark_as_placed() -> void:
	is_placed_on_board = true


func mark_as_available(color: Color) -> void:
	is_placed_on_board = false
	category_color = color
	
