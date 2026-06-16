class_name RunningState
extends PlayerState

const FOOTSTEPS: Array[AudioStream] = [
	preload("res://assets/shared/audio/player/Dirt Run 1.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 2.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 3.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 4.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 5.wav")
]

var step_timer: float = 0.0
const STEP_DELAY: float = 0.32

func enter() -> void:
	step_timer = 0.0 # Trigger first step immediately on transition

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and player.can_attack:
		player.can_attack = false
		var success = await player.request_attack()
		player.can_attack = true
		if success:
			state_machine.transition_to("attacking")

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction == Vector2.ZERO:
		state_machine.transition_to("idle")
		return
		
	step_timer -= _delta
	if step_timer <= 0.0:
		step_timer = STEP_DELAY
		_play_footstep()
	
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

func _play_footstep() -> void:
	var sfx = FOOTSTEPS[randi() % FOOTSTEPS.size()]
	AudioManager.play_sfx_2d(sfx, player.global_position, 0.1, "SFX")
