## Handles the main menu interface, including login, registration, and navigation between them.
class_name MainMenu
extends Control

## Reference to the login panel container.
@onready var login_panel: Control = $LoginPanel
## Reference to the registration panel container.
@onready var register_panel: Control = $RegisterPanel

## LineEdit for the registration username input.
@onready var reg_username_edit: LineEdit \
		= $RegisterPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/UsernameEdit
## LineEdit for the registration password input.
@onready var reg_password_edit: LineEdit \
		= $RegisterPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/PasswordEdit

## LineEdit for the login username input.
@onready var login_username_edit: LineEdit \
		= $LoginPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/UsernameEdit
## LineEdit for the login password input.
@onready var login_password_edit: LineEdit \
		= $LoginPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/PasswordEdit

## Notification UI component to display feedback messages to the user.
@warning_ignore("shadowed_variable_base_class") @onready var notification: Notification = $Notification


## Called when the node enters the scene tree for the first time.
## Connects authentication signals and plays the main menu theme.
func _ready() -> void:
	AuthManager.register_attempted.connect(_on_register_attempted)
	AuthManager.login_attempted.connect(_on_login_attempted)
	AudioManager.play_music(preload("res://assets/shared/audio/music/1. Moonspire.wav"))


## Called every frame. Unused but preserved for potential future logic.
func _process(_delta: float) -> void:
	pass


## Switches the active view from the login panel to the register panel.
func _on_go_register_button_pressed() -> void:
	login_panel.hide()
	register_panel.show()


## Switches the active view from the register panel back to the login panel.
func _on_go_back_button_pressed() -> void:
	register_panel.hide()
	login_panel.show()


## Triggers registration using the entered username and password.
func _on_try_register_button_pressed() -> void:
	var username: String = reg_username_edit.text
	var password: String = reg_password_edit.text
	AuthManager.register(username, password)


## Callback triggered when a registration attempt finishes.
## Displays the result message and switches to login if successful.
func _on_register_attempted(success: bool, message: String) -> void:
	if success:
		reg_username_edit.clear()
		reg_password_edit.clear()
		register_panel.hide()
		login_panel.show()
		notification.show_notification(message)
	else:
		AudioManager.play_sfx(preload("res://assets/shared/audio/ui/main_menu_notification.wav"), 0.0, "SFX")
		notification.show_notification(message)


## Triggers login using the entered username and password.
func _on_try_login_button_pressed() -> void:
	var username: String = login_username_edit.text
	var password: String = login_password_edit.text
	AuthManager.login(username, password)


## Callback triggered when a login attempt finishes.
## Displays the result message and plays sound feedback on failure.
func _on_login_attempted(_success: bool, message: String) -> void:
	if not _success:
		AudioManager.play_sfx(preload("res://assets/shared/audio/ui/main_menu_notification.wav"), 0.0, "SFX")
	notification.show_notification(message)
