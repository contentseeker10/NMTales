class_name AttackingState
extends PlayerState

func enter() -> void:
	player.sprite.play("attack_1_down")
	player.velocity = Vector2.ZERO
	
	await player.sprite.animation_finished
	
	state_machine.transition_to("idle")
