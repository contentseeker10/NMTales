## Manages the user interface for dialogue sequences with NPCs.
## Displays conversation history, character name/sprites, and player choice buttons.
class_name Dialogue
extends CanvasLayer

## Label that displays the NPC's name.
@onready var npc_name_label: Label = $NPCNameLabel
## Sprite used to show the NPC's portrait or animated representation.
@onready var npc_sprite: AnimatedSprite2D = $CenterContainer/AnimatedSprite2D
## Container that holds the message history.
@onready var chat_box: VBoxContainer = $VBoxContainer/PanelContainer/ScrollContainer/MarginContainer/ChatBox

## Grid containing the dialogue buttons for the player's choices.
@onready var button_grid: GridContainer = $VBoxContainer/GridContainer

## PackedScene instantiated to display the NPC's dialogue lines.
@export var npc_answer: PackedScene
## PackedScene instantiated to display the player's dialogue lines.
@export var player_answer: PackedScene

## The NPC instance involved in this dialogue sequence.
var npc: NPC

## SpriteFrames used to animate the NPC's sprite.
var npc_sprite_frames: SpriteFrames


## Initializes the dialogue UI by setting the NPC's name and starting its idle animation.
func _ready() -> void:
	npc_name_label.text = npc.npc_name
	if npc_sprite_frames:
		npc_sprite.sprite_frames = npc_sprite_frames
		npc_sprite.play("idle_down")


## Adds a dialogue entry from the NPC to the chat box.
func add_npc_answer(text: String) -> void:
	var answer: RichTextLabel = npc_answer.instantiate()
	answer.append_text("[b]" + npc.npc_id + ":[/b]\n")
	answer.add_text(text)
	chat_box.add_child(answer)


## Adds a dialogue entry from the player to the chat box.
func add_player_answer(text: String) -> void:
	var answer: RichTextLabel = player_answer.instantiate()
	answer.append_text("[b]" + AuthManager.current_user_info.get("username", "Player") + ":[/b]\n")
	answer.add_text(text)
	chat_box.add_child(answer)


## Displays a list of choices as clickable buttons for the player.
func show_choices(choices: Array) -> void:
	var buttons: Array = button_grid.get_children()
	var count: int = min(choices.size(), buttons.size())
	for i in range(count):
		buttons[i].show()
		buttons[i].text = choices[i].get("text", "error")
		buttons[i].pressed.connect(func(): DialogueManager.select_choice(choices[i]), CONNECT_ONE_SHOT)


## Clears all choice buttons, resetting their text, hiding them, and disconnecting actions.
func clear_choices_ui() -> void:
	for button in button_grid.get_children():
		button.text = ""
		button.hide()
		for connection in button.pressed.get_connections():
			button.pressed.disconnect(connection.callable)
