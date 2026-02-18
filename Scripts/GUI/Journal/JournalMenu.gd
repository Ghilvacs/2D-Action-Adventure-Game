extends CanvasLayer

@onready var sections_container: HBoxContainer = $Control/MarginContainer/VBoxContainer/SectionsContainer
@onready var button_objectives: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonObjectives
@onready var button_equipment: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonEquipment
@onready var button_bestiary: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonBestiary
@onready var button_environment: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonEnvironment
@onready var button_archive: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonArchive
@onready var topic_list_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/HSplitContainer/ScrollContainer/TopicListContainer
@onready var scroll_container_overview: ScrollContainer = $Control/MarginContainer/VBoxContainer/HSplitContainer/DetailsPanel/MarginContainer/DetailsContainer/HBoxContainer/ScrollContainerOverview
@onready var button_journal: Button = $Control/HBoxContainer/ButtonJournal
@onready var button_board: Button = $Control/HBoxContainer/ButtonBoard
@onready var detail_title_label: Label = $Control/MarginContainer/VBoxContainer/HSplitContainer/DetailsPanel/MarginContainer/DetailsContainer/DetailTitleLabel
@onready var overview_description_label: RichTextLabel = $Control/MarginContainer/VBoxContainer/HSplitContainer/DetailsPanel/MarginContainer/DetailsContainer/HBoxContainer/ScrollContainerOverview/OverviewDescriptionLabel
@onready var entry_list_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/HSplitContainer/DetailsPanel/MarginContainer/DetailsContainer/HBoxContainer/ScrollContainer/EntryListContainer
@onready var details_panel: Panel = $Control/MarginContainer/VBoxContainer/HSplitContainer/DetailsPanel
@onready var board_panel: Panel = $Control/MarginContainer/VBoxContainer/HSplitContainer/BoardPanel

enum Category { OBJECTIVE, EQUIPMENT, BESTIARY, ENVIRONMENT, ARCHIVE }
enum ViewMode { JOURNAL, BOARD }

var current_category = Category.OBJECTIVE
var current_view_mode = ViewMode.JOURNAL
var current_topic: JournalTopic
var in_journal: bool = false
var entry_text_indices: Dictionary = {}

signal JournalShown
signal JournalHidden


func _ready() -> void:
	button_objectives.pressed.connect(show_category.bind(Category.OBJECTIVE))
	button_equipment.pressed.connect(show_category.bind(Category.EQUIPMENT))
	button_bestiary.pressed.connect(show_category.bind(Category.BESTIARY))
	button_environment.pressed.connect(show_category.bind(Category.ENVIRONMENT))
	button_archive.pressed.connect(show_category.bind(Category.ARCHIVE))
	button_journal.pressed.connect(set_view_mode.bind(ViewMode.JOURNAL))
	button_board.pressed.connect(set_view_mode.bind(ViewMode.BOARD))

	JournalManager.journal_updated.connect(_on_journal_updated)
	JournalManager.topic_removed_from_board.connect(_on_topic_removed_from_board)
	
	show_category(Category.OBJECTIVE)
	set_view_mode(ViewMode.JOURNAL)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		if JournalManager.is_journal_update_overlay and JournalManager.last_unlocked_entry:
			open_to_specific_entry(JournalManager.last_unlocked_entry)
		elif not in_journal:
			show_journal()
		else:
			hide_journal()
				
		get_viewport().set_input_as_handled()


func set_view_mode(mode: ViewMode) -> void:
	current_view_mode = mode
	
	match mode:
		ViewMode.JOURNAL:
			details_panel.visible = true
			board_panel.visible = false
		ViewMode.BOARD:
			details_panel.visible = false
			board_panel.visible = true
			board_panel.reset_view()


func show_journal() -> void:
	PauseMenu.hide_pause_menu()
	InventoryMenu.hide_inventory_menu()
	JournalUpdateOverlay.hide_journal_update_overlay()
	visible = true
	in_journal = true
	GlobalPlayerManager.player.set_input_locked(true)
	JournalShown.emit()


func hide_journal() -> void:
	visible = false
	in_journal = false
	GlobalPlayerManager.player.set_input_locked(false)
	JournalHidden.emit()


func show_category(category: int) -> void:
	current_category = category
	_clear_topic_list()
	_clear_entry_list()
	
	var topics = JournalManager.get_known_topics(category)
	
	for topic in topics:
		var button = DraggableTopicButton.new()
		button.topic_data = topic
		button.text = topic.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(200.0, 0.0)
		button.add_theme_font_size_override("Arial", 30)
		
		if JournalManager.is_topic_on_board(topic):
			button.mark_as_placed()
		
		button.pressed.connect(select_topic.bind(topic))
		topic_list_container.add_child(button)
	
	if not topics.is_empty():
		select_topic(topics[0])
		topic_list_container.get_child(0).grab_focus()
	else:
		detail_title_label.text = ""
		overview_description_label.text = ""
		current_topic = null


func select_topic(topic: JournalTopic) -> void:
	current_topic = topic
	_clear_entry_list()
	detail_title_label.text = topic.title
	
	for child in entry_list_container.get_children():
		child.queue_free()
	entry_text_indices.clear()
	
	var entries = JournalManager.get_entries_for_topic(topic)
	var full_display_text: String = ""
	
	for entry in entries:
		var button = Button.new()
		button.text = entry.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_highlight_entry.bind(entry))
		entry_list_container.add_child(button)
		entry_text_indices[entry] = full_display_text.length()
		full_display_text += entry.description + "\n\n"
	
	overview_description_label.text = full_display_text


func open_to_specific_entry(entry: JournalEntry) -> void:
	if not in_journal:
		show_journal()
		
	var parent_topic = entry.parent_topic
	set_view_mode(ViewMode.JOURNAL)
	
	if parent_topic:
		show_category(parent_topic.category)
		select_topic(parent_topic)
		_highlight_entry(entry)


func _highlight_entry(selected_entry: JournalEntry) -> void:
	var entries = JournalManager.get_entries_for_topic(current_topic)
	var final_bbcode = ""
	
	for entry in entries:
		if entry == selected_entry:
			final_bbcode += "[color=#ffab4b]" + entry.description + "[/color]\n\n"
		else:
			final_bbcode += "[color=#ffffff]" + entry.description + "[/color]\n\n"
	
	overview_description_label.text = final_bbcode
	
	await get_tree().process_frame
	
	if entry_text_indices.has(selected_entry):
		var character_index = entry_text_indices[selected_entry]
		var line_index = overview_description_label.get_character_line(character_index)
		var y_position = overview_description_label.get_line_offset(line_index)
		var tween = create_tween()
		tween.tween_property(scroll_container_overview, "scroll_vertical", y_position, 0.3).set_trans(Tween.TRANS_CUBIC)


func _clear_topic_list() -> void:
	for child in topic_list_container.get_children():
		child.queue_free()


func _clear_entry_list() -> void:
	for child in entry_list_container.get_children():
		child.queue_free()


func _on_journal_updated() -> void:
	show_category(current_category)
	
	if current_topic:
		select_topic(current_topic)


func _on_topic_removed_from_board(topic: JournalTopic) -> void:
	for child in topic_list_container.get_children():
		if child is DraggableTopicButton and child.topic_data == topic:
			child.mark_as_available()
