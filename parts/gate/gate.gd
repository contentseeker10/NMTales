@tool
class_name Gate
extends TileMapLayer

@export var unlock_quest_id: String
@export var unlocked: bool:
	set(value):
		unlocked = value
		if is_node_ready():
			toggle()


func _ready() -> void:
	if Engine.is_editor_hint():
		toggle()
		return
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_updated.connect(_on_quest_updated)
	_check_unlock_state()


func _check_unlock_state() -> void:
	var is_completed = false
	var is_active = false
	
	if unlock_quest_id.contains(":"):
		is_completed = QuestManager.completed_quest_ids.has(unlock_quest_id)
		if QuestManager.active_quest:
			var active_composite = QuestManager.active_quest.giver + ":" + QuestManager.active_quest.id
			is_active = active_composite == unlock_quest_id
	else:
		is_completed = QuestManager.completed_quest_ids.has(unlock_quest_id)
		if not is_completed:
			for comp in QuestManager.completed_quest_ids:
				if comp.ends_with(":" + unlock_quest_id):
					is_completed = true
					break
		is_active = QuestManager.active_quest and QuestManager.active_quest.id == unlock_quest_id
		
	unlocked = is_completed or is_active
	toggle()


func _on_quest_completed(_quest: Quest) -> void:
	_check_unlock_state()


func _on_quest_updated(_quest: Quest) -> void:
	_check_unlock_state()


func toggle() -> void:
	if unlocked:
		set_cell(Vector2i.ZERO, 1, Vector2i(0, 5))
	else:
		set_cell(Vector2i.ZERO, 1, Vector2i(0, 3))
