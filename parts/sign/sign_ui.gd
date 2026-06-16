## A UI overlay for displaying sign titles and text content.
##
## This class pauses the game when shown and resumes the game when closed.
class_name SignUI
extends CanvasLayer

## Label that displays the title of the sign.
@onready var title_label: Label = $CenterContainer/PanelContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
## RichTextLabel that displays the main content of the sign.
@onready var content_text: RichTextLabel = $CenterContainer/PanelContainer/PanelContainer/MarginContainer/VBoxContainer/ContentText


## Called when the node enters the scene tree. Pauses the game loop.
func _ready() -> void:
	get_tree().paused = true


## Called when the exit button is pressed. Unpauses the game loop and frees the UI.
func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	queue_free()

