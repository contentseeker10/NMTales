## State representing the player running.
##
## Handles player movement input, updating sprite animations based on
## movement direction, playing footstep sound effects, and transitions to
## idle or attacking states.
class_name RunningState
extends PlayerState

## Footstep audio streams played randomly while running.
const FOOTSTEPS: Array[AudioStream] = [
	preload("res://assets/shared/audio/player/Dirt Run 1.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 2.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 3.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 4.wav"),
	preload("res://assets/shared/audio/player/Dirt Run 5.wav")
]

## Timer to track delay between playing footstep sounds.
var step_timer: float = 0.0
## Delay in seconds between each footstep sound effect.
const STEP_DELAY: float = 0.32

## Called when entering the running state.
## Resets the step timer to trigger a footstep sound immediately.
func enter() -> void:
	step_timer = 0.0 # Trigger first step immediately on transition

## Called when exiting the running state.
func exit() -> void:
	pass

## Handles player inputs, such as requesting an attack transition.
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and player.can_attack:
		player.can_attack = false
		var success = await player.request_attack()
		player.can_attack = true
		if success:
			state_machine.transition_to("attacking")

## Called during the main game loop update process.
func update(_delta: float) -> void:
	pass

## Handles movement physics updates, directional animations, state transitions,
## and footstep sound timing based on player input.
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

## Plays a random footstep sound effect from the footstep array.
func _play_footstep() -> void:
	var sfx = FOOTSTEPS[randi() % FOOTSTEPS.size()]
	AudioManager.play_sfx_2d(sfx, player.global_position, 0.1, "SFX")
