## Represents a quest in the game, tracking its metadata, objectives, and progress.
class_name Quest
extends RefCounted

## The unique identifier of the quest.
var id: String = ""
## The display title of the quest.
var title: String = ""
## The character or entity that hands out the quest.
var giver: String = ""
## The detailed description of the quest objective or story.
var description: String = ""
## The type of objective (e.g., "kill", "gather", "visit").
var type: String = ""
## The target object, enemy, or location for the objective.
var target: String = ""
## The current count of progress toward the objective.
var current_amount: int = 0
## The total count required to complete the objective.
var required_amount: int = 1


## Initializes the quest using the provided data dictionary.
func _init(quest_data: Dictionary) -> void:
	_parse_quest_data(quest_data)


## Parses and assigns the quest properties from the configuration dictionary.
func _parse_quest_data(quest_data: Dictionary) -> void:
	id = quest_data.get("id", "error")
	giver = quest_data.get("giver", "error")
	title = quest_data.get("title", "error")
	description = quest_data.get("description", "error")
	var objective: Dictionary = quest_data.get("objective", {})
	type = objective.get("type", "error")
	target = objective.get("target", "error")
	current_amount = objective.get("current_amount", 0)
	required_amount = objective.get("required_amount", 0)


## Checks if the current progress meets or exceeds the required target amount.
func is_objective_done() -> bool:
	return current_amount >= required_amount

