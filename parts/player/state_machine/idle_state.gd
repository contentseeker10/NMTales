class_name IdleState
extends PlayerState

func enter() -> void:
	player.sprite.play("idle_down")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") \
	or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		state_machine.transition_to("running")
	
	if event.is_action_pressed("attack"):
		state_machine.transition_to("attacking")
