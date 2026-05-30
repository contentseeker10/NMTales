class_name Quest
extends Node

var data: Dictionary


func _init(quest_giver: String, quest_id: String) -> void:
	var path: String = "res://assets/shared/quests/" + quest_giver + "/" + quest_id + ".json"
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var content: String = file.get_as_text()
		file.close()
		data = JSON.parse_string(content)
	else:
		push_error("Quest was not found: " + path)
		data = {}
