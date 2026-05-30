extends Node

var dialogue_scene: PackedScene = preload("res://ui/menus/dialogue/dialogue.tscn")
var dialogue: Dialogue


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_dialogue()


func start_dialogue(npc: NPC) -> void:
	get_tree().paused = true
	_add_dialogue_scene(npc)

func _add_dialogue_scene(npc: NPC) -> void:
	dialogue = dialogue_scene.instantiate()
	dialogue.npc_name = npc.npc_id
	dialogue.npc_sprite_frames = npc.sprite.sprite_frames
	get_tree().current_scene.add_child(dialogue)


func end_dialogue() -> void:
	dialogue.queue_free()
	get_tree().paused = false
