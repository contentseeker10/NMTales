@tool
## A UI component representing an achievement plate.
##
## This control displays an achievement's icon, title, and description.
## It dynamically adjusts its visual appearance (such as borders, modulate, and colors)
## depending on whether the achievement has been unlocked.
class_name AchievementPlate
extends Control

## Container panel for the achievement plate.
@onready var panel: PanelContainer = $PanelContainer
## Icon representing the achievement.
@onready var icon: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Icon
## Label showing the achievement title.
@onready var title_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/TitleLabel
## Label showing the achievement description.
@onready var description_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DescriptionLabel

## Whether the achievement is unlocked.
## Modifying this changes the visual state of the plate.
@export var unlocked: bool = false:
	set(value):
		unlocked = value
		if is_node_ready():
			toggle_state()


func _ready() -> void:
	toggle_state()


## Toggles the visual state of the achievement plate elements (panel style,
## icon opacity, and font colors) depending on the [member unlocked] property.
func toggle_state() -> void:
	if unlocked:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("4c3a33")
		style.border_color = Color("FEB358")
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		panel.add_theme_stylebox_override("panel", style)
		icon.modulate = Color.WHITE
		title_label.add_theme_color_override("font_color", Color.WHITE)
		description_label.add_theme_color_override("font_color", Color.DARK_GRAY)
	else:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("4c3a33")
		style.border_color = Color("523100")
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		panel.add_theme_stylebox_override("panel", style)
		icon.modulate = Color.from_rgba8(255, 255, 255, 50)
		title_label.add_theme_color_override("font_color", Color.from_rgba8(150, 150, 150, 255))
		description_label.add_theme_color_override("font_color", Color.from_rgba8(100, 100, 100, 255))

