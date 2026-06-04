class_name IdleState
extends PlayerState

func enter() -> void:
	player.sprite.play("idle_" + state_machine.get_direction_name())

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and player.can_attack:
		state_machine.transition_to("attacking")

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		state_machine.transition_to("running")
