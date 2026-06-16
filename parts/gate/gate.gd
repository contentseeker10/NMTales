@tool
## A tilemap-based gate that unlocks (opens) based on the state of a specific quest.
##
## The gate monitors quest completion and updates from the [QuestManager].
## It can be unlocked if the target quest is either active or completed.
class_name Gate
extends TileMapLayer

## The unique identifier of the quest required to unlock the gate.
## Can specify the full "giver:id" composite or just the quest "id".
@export var unlock_quest_id: String
## Indicates whether the gate is currently unlocked (open).
## Changing this value triggers [method toggle] to update the cell visuals.
@export var unlocked: bool:
	set(value):
		unlocked = value
		if is_node_ready():
			toggle()


## Called when the node enters the scene tree. Initializes event connections
## with [QuestManager] and checks the initial unlock state.
func _ready() -> void:
	if Engine.is_editor_hint():
		toggle()
		return
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_updated.connect(_on_quest_updated)
	_check_unlock_state()


## Evaluates the current quest state to determine if the gate should be unlocked.
## Checks if the target quest is completed or actively in progress.
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


## Callback triggered when a quest is completed. Re-evaluates the unlock state.
func _on_quest_completed(_quest: Quest) -> void:
	_check_unlock_state()


## Callback triggered when a quest is updated. Re-evaluates the unlock state.
func _on_quest_updated(_quest: Quest) -> void:
	_check_unlock_state()


## Updates the visual cell state of the gate on the TileMap.
## Shows an open gate cell if [member unlocked] is true, otherwise shows a closed gate cell.
func toggle() -> void:
	if unlocked:
		set_cell(Vector2i.ZERO, 1, Vector2i(0, 5))
	else:
		set_cell(Vector2i.ZERO, 1, Vector2i(0, 3))

