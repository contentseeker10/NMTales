extends Control

@onready var settings_panel: Control = $SettingsPanel
@onready var music_checkbox: PanelContainer = $SettingsPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/CustomCheckbox

func _ready() -> void:
	music_checkbox.set_checked(not AudioManager.is_bus_muted("Music"))
	music_checkbox.toggled.connect(_on_music_toggled)

func _on_settings_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		settings_panel.show()
	else:
		settings_panel.hide()

func _on_music_toggled(enabled: bool) -> void:
	AudioManager.set_bus_mute("Music", not enabled)
