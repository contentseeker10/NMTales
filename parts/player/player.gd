class_name Player extends CharacterBody2D

enum STATE { IDLE, RUNNING, ATTACKING }

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var _state: STATE = STATE.IDLE

@export var _speed: float = 1.0
@export var _acceleration: float = 10.0

func _process(delta: float) -> void:
	_handle_input()

func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * _speed * 100.0, delta * _acceleration * 100.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * _acceleration * 100.0)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("attack"):
		print("Attacking!")

func _handle_input() -> void:
	if not Input.is_anything_pressed():
		_sprite.play("idle_down")
	match _state:
		STATE.IDLE:
			if Input.is_action_pressed("move_up"):
				_sprite.play("run_up")
			elif Input.is_action_pressed("move_left"):
				_sprite.play("run_left")
			elif Input.is_action_pressed("move_down"):
				_sprite.play("run_down")
			elif Input.is_action_pressed("move_right"):
				_sprite.play("run_right")
		STATE.RUNNING:
			pass
		STATE.ATTACKING:
			pass
