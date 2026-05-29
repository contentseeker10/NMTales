class_name Main
extends Control

@onready var login_panel: Control = $LoginPanel
@onready var register_panel: Control = $RegisterPanel

@onready var reg_username_edit: LineEdit \
		= $RegisterPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/UsernameEdit
@onready var reg_password_edit: LineEdit \
		= $RegisterPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/PasswordEdit

@onready var login_username_edit: LineEdit \
		= $LoginPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/UsernameEdit
@onready var login_password_edit: LineEdit \
		= $LoginPanel/MarginContainer/MarginContainer/VBoxContainer/VBoxContainer/PasswordEdit

@onready var notification: Notification = $Notification


func _ready() -> void:
	AuthManager.register_attempted.connect(_on_register_attempted)
	AuthManager.login_attempted.connect(_on_login_attempted)


func _process(delta: float) -> void:
	pass


func _on_go_register_button_pressed() -> void:
	login_panel.hide()
	register_panel.show()


func _on_go_back_button_pressed() -> void:
	register_panel.hide()
	login_panel.show()


func _on_try_register_button_pressed() -> void:
	var username: String = reg_username_edit.text
	var password: String = reg_password_edit.text
	AuthManager.register(username, password)

func _on_register_attempted(success: bool, message: String) -> void:
	if success:
		reg_username_edit.clear()
		reg_password_edit.clear()
		register_panel.hide()
		login_panel.show()
		notification.show_notification(message)
	else:
		notification.show_notification(message)


func _on_try_login_button_pressed() -> void:
	var username: String = login_username_edit.text
	var password: String = login_password_edit.text
	AuthManager.login(username, password)

func _on_login_attempted(success: bool, message: String) -> void:
	if success:
		LocationManager.entry_location("test")
	else:
		notification.show_notification(message)
