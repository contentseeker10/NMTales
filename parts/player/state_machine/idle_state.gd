class_name IdleState
extends PlayerState

func enter() -> void:
	match state_machine.direction:
		Vector2.UP:
			player.sprite.play("idle_up")
		Vector2.LEFT:
			player.sprite.play("idle_left")
		Vector2.DOWN:
			player.sprite.play("idle_down")
		Vector2.RIGHT:
			player.sprite.play("idle_right")

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") \
	or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		state_machine.transition_to("running")
	
	if event.is_action_pressed("attack"):
		state_machine.transition_to("attacking")

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass
