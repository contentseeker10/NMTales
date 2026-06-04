class_name RunningState
extends PlayerState

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		state_machine.transition_to("attacking")

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction == Vector2.ZERO:
		state_machine.transition_to("idle")
		return
	
	player.velocity = input_direction * player.speed
	player.move_and_slide()
	
	if input_direction.x > 0:
		player.sprite.play("run_right")
		state_machine.direction = Vector2.RIGHT
	elif input_direction.x < 0:
		player.sprite.play("run_left")
		state_machine.direction = Vector2.LEFT
	elif input_direction.y > 0:
		player.sprite.play("run_down")
		state_machine.direction = Vector2.DOWN
	elif input_direction.y < 0:
		player.sprite.play("run_up")
		state_machine.direction = Vector2.UP
