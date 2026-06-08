class_name AttackingState
extends PlayerState

func enter() -> void:
	player.velocity = Vector2.ZERO
	player.sprite.play("attack_1_" + state_machine.get_direction_name())
	await player.sprite.animation_finished
	player.sprite.play("attack_2_" + state_machine.get_direction_name())
	await player.sprite.animation_finished
	state_machine.transition_to("idle")

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
