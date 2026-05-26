extends Control

@onready var settings_panel: Control = $SettingsPanel
@onready var login_panel: Control = $LoginPanel
@onready var register_panel: Control = $RegisterPanel

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_settings_button_toggled(toggled_on: bool) -> void:
	settings_panel.show() if toggled_on else settings_panel.hide()

func _on_register_button_pressed() -> void:
	login_panel.hide()
	register_panel.show()

func _on_back_button_pressed() -> void:
	register_panel.hide()
	login_panel.show()
