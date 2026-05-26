class_name Notification
extends MarginContainer


@onready var timer: Timer = $Timer
@onready var label: Label = $NotificationLabel


func show_notification(message: String) -> void:
	_reset_notification()
	label.text = message
	label.show()
	timer.start()
	await timer.timeout
	label.hide()

func _reset_notification() -> void:
	timer.stop()
	label.hide()
