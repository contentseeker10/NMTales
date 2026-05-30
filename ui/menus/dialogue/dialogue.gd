class_name Dialogue
extends CanvasLayer

@onready var npc_name_label: Label = $NPCNameLabel
@onready var npc_sprite: AnimatedSprite2D = $CenterContainer/AnimatedSprite2D
@onready var chat_box: VBoxContainer = $VBoxContainer/PanelContainer/ScrollContainer/MarginContainer/ChatBox

@export var npc_name: String
@export var npc_answer: PackedScene
@export var player_answer: PackedScene

var npc_sprite_frames: SpriteFrames


func _ready() -> void:
	npc_name_label.text = npc_name
	if npc_sprite_frames:
		npc_sprite.sprite_frames = npc_sprite_frames
		npc_sprite.play("idle_down")


func add_npc_answer(text: String) -> void:
	var answer: RichTextLabel = npc_answer.instantiate()
	answer.append_text("[b]" + npc_name + ":[/b]\n")
	answer.add_text(text)
	chat_box.add_child(answer)


func add_player_answer(text: String) -> void:
	var answer: RichTextLabel = player_answer.instantiate()
	answer.append_text("[b]" + AuthManager.current_user_info.get("username", "Player") + ":[/b]\n")
	answer.add_text(text)
	chat_box.add_child(answer)
