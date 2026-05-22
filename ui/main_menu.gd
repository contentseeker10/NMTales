extends Control

@onready var settings_panel = $SettingsPanel

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass


func _on_settings_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		settings_panel.show()
	else:
		settings_panel.hide()
