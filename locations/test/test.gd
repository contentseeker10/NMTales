extends Node2D


func _ready() -> void:
	LocationManager.spawn_player()
	var quest: Quest = Quest.new("npc_test", "quest_1")
	QuestManager.accept_quest(quest)
