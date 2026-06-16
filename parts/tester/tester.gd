## A node that manages player interactions to initiate tests/quizzes in the game world.
##
## The Tester class displays a test topic icon/label when the player is nearby,
## controls interaction state, prevents player attacks during interaction,
## and starts the corresponding test if the required quest is active.
class_name Tester
extends Node2D

## Reference to the Label node that displays the test topic or action icon.
@onready var _action_icon: Label = $ActionIcon

## The category or type identifier of the test.
@export var test_type: String
## The specific topic or title of the test.
@export var test_topic: String
## The ID of the quest that must be active to trigger this test.
@export var required_quest_id: String

## Tracks whether the player is close enough to interact with the tester.
var is_available: bool = false


## Called when the node is added to the scene. Initializes the action icon text.
func _ready() -> void:
	_action_icon.text = test_topic


## Shows the action icon when the player enters the detection range.
func _on_label_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.show()


## Hides the action icon when the player leaves the detection range.
func _on_label_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.hide()


## Highlights the action icon and makes the test available when the player is close enough.
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.add_theme_color_override("font_color", Color.YELLOW)
		body.can_attack = false
		is_available = true


## Resets the action icon highlight and makes the test unavailable when the player moves away.
func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body and body is Player:
		_action_icon.add_theme_color_override("font_color", Color.WHITE)
		body.can_attack = true
		is_available = false


## Handles input events on the click area to start the test when clicked.
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and not TestManager.is_test_active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
				if QuestManager.active_quest and required_quest_id == QuestManager.active_quest.id:
					TestManager.start_test(test_type, test_topic)

