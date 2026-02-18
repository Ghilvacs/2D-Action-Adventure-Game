class_name DraggableTopicButton extends Button

var topic_data: JournalTopic
var is_placed_on_board: bool = false


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
	modulate = Color(0.5, 0.5, 0.5, 0.5)


func mark_as_available() -> void:
	is_placed_on_board = false
	modulate = Color(1, 1, 1, 1)
