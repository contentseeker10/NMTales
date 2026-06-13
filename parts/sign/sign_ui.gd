class_name SignUI
extends CanvasLayer

@onready var title_label: Label = $CenterContainer/PanelContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var content_text: RichTextLabel = $CenterContainer/PanelContainer/PanelContainer/MarginContainer/VBoxContainer/ContentText


func _ready() -> void:
	get_tree().paused = true


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	queue_free()
