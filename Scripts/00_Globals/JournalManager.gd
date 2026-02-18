extends Node

var unlocked_entries: Array[JournalEntry] = []
var topics_on_board: Array[JournalTopic] = []
var is_journal_update_overlay: bool = false 
var last_unlocked_entry: JournalEntry = null

signal journal_updated(entry: JournalEntry)
signal topic_removed_from_board(topic: JournalTopic)


func get_known_topics(category_enum: int) -> Array[JournalTopic]:
	var known_topics: Array[JournalTopic] = []
	
	for entry in unlocked_entries:
		if entry.parent_topic and entry.parent_topic.category == category_enum:
			if not known_topics.has(entry.parent_topic):
				known_topics.append(entry.parent_topic)
	
	return known_topics


func get_entries_for_topic(topic: JournalTopic) -> Array[JournalEntry]:
	var entries: Array[JournalEntry] = []
	
	for entry in unlocked_entries:
		if entry.parent_topic == topic:
			entries.append(entry)
	return entries


func unlock_entry(entry: JournalEntry) -> void:
	if not unlocked_entries.has(entry):
		JournalUpdateOverlay.JournalUpdateOverlayShown.connect(turn_on_update_overlay)
		JournalUpdateOverlay.JournalUpdateOverlayHidden.connect(turn_off_update_overlay)
		unlocked_entries.append(entry)
		last_unlocked_entry = entry
		emit_signal("journal_updated")
		JournalUpdateOverlay.show_journal_update_overlay(entry.title)


func register_topic_om_board(topic: JournalTopic) -> void:
	if not topics_on_board.has(topic):
		topics_on_board.append(topic)


func unregister_topic_om_board(topic: JournalTopic) -> void:
	if topics_on_board.has(topic):
		topics_on_board.erase(topic)
		emit_signal("topic_removed_from_board", topic)


func is_topic_on_board(topic: JournalTopic) -> bool:
	return topics_on_board.has(topic)


func turn_on_update_overlay() -> void:
	is_journal_update_overlay = true


func turn_off_update_overlay() -> void:
	is_journal_update_overlay = false
