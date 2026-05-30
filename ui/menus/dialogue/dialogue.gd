class_name Dialogue
extends CanvasLayer

@onready var npc_name_label: Label = $NPCNameLabel
@onready var npc_sprite: AnimatedSprite2D = $CenterContainer/AnimatedSprite2D
@onready var chat_box: VBoxContainer = $VBoxContainer/PanelContainer/ScrollContainer/MarginContainer/ChatBox

@onready var button_grid: GridContainer = $VBoxContainer/GridContainer

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


func show_choices(choices: Array) -> void:
	var buttons: Array = button_grid.get_children()
	for i in range(choices.size()):
		buttons[i].show()
		buttons[i].text = choices[i].get("text", "error")
		buttons[i].pressed.connect(func(): DialogueManager.select_choice(choices[i]), CONNECT_ONE_SHOT)

func clear_choices_ui() -> void:
	for button in button_grid.get_children():
		button.text = ""
		button.hide()
