## Represents the idle state of the player.
##
## This state handles playing the idle animation in the last facing direction,
## transitions to the attacking state on attack input (if allowed), and
## transitions to the running state if movement input is detected.
class_name IdleState
extends PlayerState

## Called when the state is entered. Plays the appropriate idle animation
## based on the current facing direction.
func enter() -> void:
	player.sprite.play("idle_" + state_machine.get_direction_name())

## Called when exiting the state. Currently does nothing.
func exit() -> void:
	pass

## Processes input events to handle transitioning to the attacking state.
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and player.can_attack:
		player.can_attack = false
		var success = await player.request_attack()
		player.can_attack = true
		if success:
			state_machine.transition_to("attacking")

## Called during the main frame update process. Currently does nothing.
func update(_delta: float) -> void:
	pass

## Called during the physics frame update. Checks for movement input to
## transition to the running state.
func physics_update(_delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		state_machine.transition_to("running")

