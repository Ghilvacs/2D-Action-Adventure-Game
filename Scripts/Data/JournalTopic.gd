class_name JournalTopic extends Resource

enum Category { OBJECTIVE, EQUIPMENT, BESTIARY, ENVIRONMENT, ARCHIVE }

@export var category: JournalTopic.Category
@export var title: String
@export var icon: Texture2D
@export_multiline var overview_text: String
