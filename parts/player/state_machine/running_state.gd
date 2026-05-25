class_name RunningState
extends PlayerState

func physics_update(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction == Vector2.ZERO:
		state_machine.transition_to("idle")
		return
	
	player.velocity = input_direction * player.speed
	player.move_and_slide()
	
	if input_direction.x > 0:
		player.sprite.play("run_right")
	elif input_direction.x < 0:
		player.sprite.play("run_left")
	elif input_direction.y > 0:
		player.sprite.play("run_down")
	elif input_direction.y < 0:
		player.sprite.play("run_up")
