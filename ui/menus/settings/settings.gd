## Manages the settings menu UI interface.
##
## This class controls the visibility of the settings panel and handles UI interactions
## such as toggling the music state using [AudioManager].
extends Control

## Reference to the settings panel container.
@onready var settings_panel: Control = $SettingsPanel
## Reference to the checkbox control that toggles music.
@onready var music_checkbox: PanelContainer = $SettingsPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/CustomCheckbox


## Called when the node enters the scene tree.
## Initializes the checkbox state based on the audio manager's bus status and connects toggle signals.
func _ready() -> void:
	music_checkbox.set_checked(not AudioManager.is_bus_muted("Music"))
	music_checkbox.toggled.connect(_on_music_toggled)


## Shows or hides the settings panel when the settings button is toggled.
func _on_settings_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		settings_panel.show()
	else:
		settings_panel.hide()


## Mutes or unmutes the music audio bus based on the toggled state.
func _on_music_toggled(enabled: bool) -> void:
	AudioManager.set_bus_mute("Music", not enabled)

