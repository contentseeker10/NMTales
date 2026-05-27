extends Control

@onready var settings_panel: Control = $SettingsPanel

func _on_settings_button_toggled(toggled_on: bool) -> void:
	settings_panel.show() if toggled_on else settings_panel.hide()
