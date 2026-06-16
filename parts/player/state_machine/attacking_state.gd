## A player state that handles the attack animations, sound effects, and hitbox logic.
##
## This state stops the player's movement, aligns the attack collision area to
## the player's facing direction, activates monitoring, plays a consecutive two-hit
## attack animation sequence with sound effects, and returns to the idle state.
class_name AttackingState
extends PlayerState

## Sound effect played during the first attack in the combo.
const SWORD_ATTACK_1: AudioStream = preload("res://assets/shared/audio/player/Sword Attack 1.wav")
## Sound effect played during the second attack in the combo.
const SWORD_ATTACK_2: AudioStream = preload("res://assets/shared/audio/player/Sword Attack 2.wav")

## Called when the state is entered. Stops player movement, aligns and enables
## the attack hitboxes, plays the attack animation combo, and transitions to idle.
func enter() -> void:
	player.velocity = Vector2.ZERO
	
	_rotate_attack_area()
	_toggle_attack_area(true)
	
	await _play_animations()
	
	state_machine.transition_to("idle")

## Rotates the attack collision area to face the current movement/facing direction.
func _rotate_attack_area() -> void:
	var dir := state_machine.direction
	var angle := dir.angle()
	player.attack_area.rotation = angle

## Enables or disables monitoring and monitorable properties of the player's attack area.
## [param state] True to enable the hitbox, false to disable it.
func _toggle_attack_area(state: bool) -> void:
	player.attack_area.monitoring = state
	player.attack_area.monitorable = state

## Plays the sequence of attack animations and associated sound effects.
## Waits for each animation to finish before proceeding or exiting.
func _play_animations() -> void:
	player.sprite.play("attack_1_" + state_machine.get_direction_name())
	AudioManager.play_sfx_2d(SWORD_ATTACK_1, player.global_position, 0.08, "SFX")
	await player.sprite.animation_finished
	
	player.sprite.play("attack_2_" + state_machine.get_direction_name())
	AudioManager.play_sfx_2d(SWORD_ATTACK_2, player.global_position, 0.08, "SFX")
	await player.sprite.animation_finished

## Called when the state is exited. Ensures the attack area is disabled.
func exit() -> void:
	_toggle_attack_area(false)

## Handles input events while in the attacking state.
func handle_input(_event: InputEvent) -> void:
	pass

## Called during the process update loop.
func update(_delta: float) -> void:
	pass

## Called during the physics process update loop.
func physics_update(_delta: float) -> void:
	pass

