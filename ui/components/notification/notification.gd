## A UI component that displays temporary text notifications.
##
## This component handles showing a text label with a message for a limited
## duration using a Timer, and then automatically hiding it.
class_name Notification
extends MarginContainer


## The timer controlling how long the notification remains visible.
@onready var timer: Timer = $Timer
## The label displaying the notification message.
@onready var label: Label = $NotificationLabel


## Displays a notification message.
##
## Resets any active notification, sets the text to [param message],
## shows the label, starts the timer, and hides the label when the timer times out.
func show_notification(message: String) -> void:
	_reset_notification()
	label.text = message
	label.show()
	timer.start()
	await timer.timeout
	label.hide()


## Resets the notification state.
##
## Stops the timer and hides the label immediately.
func _reset_notification() -> void:
	timer.stop()
	label.hide()

