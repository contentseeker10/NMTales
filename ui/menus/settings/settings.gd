extends Control

@onready var settings_panel: Control = $SettingsPanel

func _on_settings_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		settings_panel.show()
	else:
		settings_panel.hide()
