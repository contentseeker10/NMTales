extends PanelContainer

@onready var label: Label = $Label
@onready var check_button: TextureButton = $CenterContainer/CheckButton

func _ready():
	pass

func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		label.add_theme_color_override("font_color", Color("DFDFDF"))
	else:
		label.add_theme_color_override("font_color", Color("96827A"))
