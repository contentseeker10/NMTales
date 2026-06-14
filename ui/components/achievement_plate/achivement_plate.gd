@tool
class_name AchievementPlate
extends Control

@onready var panel: PanelContainer = $PanelContainer
@onready var icon: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Icon
@onready var title_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/DescriptionLabel

@export var unlocked: bool = false:
	set(value):
		unlocked = value
		if is_node_ready():
			toggle_state()


func _ready() -> void:
	toggle_state()


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
