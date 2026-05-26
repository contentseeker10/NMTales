class_name AttackingState
extends PlayerState

func enter() -> void:
	match state_machine.direction:
		Vector2.UP:
			player.sprite.play("attack_1_up")
			await player.sprite.animation_finished
			player.sprite.play("attack_2_up")
		Vector2.LEFT:
			player.sprite.play("attack_1_left")
			await player.sprite.animation_finished
			player.sprite.play("attack_2_left")
		Vector2.DOWN:
			player.sprite.play("attack_1_down")
			await player.sprite.animation_finished
			player.sprite.play("attack_2_down")
		Vector2.RIGHT:
			player.sprite.play("attack_1_right")
			await player.sprite.animation_finished
			player.sprite.play("attack_2_right")
	player.velocity = Vector2.ZERO
	
	await player.sprite.animation_finished
	
	state_machine.transition_to("idle")

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass
