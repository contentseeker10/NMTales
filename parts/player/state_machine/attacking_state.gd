class_name AttackingState
extends PlayerState

func enter() -> void:
	player.velocity = Vector2.ZERO
	
	_rotate_attack_area()
	_toggle_attack_area(true)
	
	await _play_animations()
	
	state_machine.transition_to("idle")

func _rotate_attack_area() -> void:
	var dir := state_machine.direction
	var angle := dir.angle()
	player.attack_area.rotation = angle

func _toggle_attack_area(state: bool) -> void:
	player.attack_area.monitoring = state
	player.attack_area.monitorable = state

func _play_animations() -> void:
	player.sprite.play("attack_1_" + state_machine.get_direction_name())
	await player.sprite.animation_finished
	player.sprite.play("attack_2_" + state_machine.get_direction_name())
	await player.sprite.animation_finished


func exit() -> void:
	_toggle_attack_area(false)

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
