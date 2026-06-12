@tool
class_name Enemy
extends CharacterBody2D

enum State { CHASE, ATTACK, DEAD }
var current_state: State = State.CHASE


func _ready() -> void:
	_update_skin()


func _physics_process(delta: float) -> void:
	match current_state:
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			_process_dead()


#region State processing

func _process_chase(delta: float) -> void:
	pass


func _process_attack(delta: float) -> void:
	pass


func _process_dead() -> void:
	queue_free()


func _get_direction_name(vel: Vector2) -> String:
	return ""

#endregion


#region Skin changer

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

enum EnemySkin { VampireGreen, VampireBlue, VampireRed }
const SKIN_TEXTURES = {
	EnemySkin.VampireGreen: preload("res://assets/shared/characters/mobs/vampire_1/vampire_1.tres"),
	EnemySkin.VampireBlue: preload("res://assets/shared/characters/mobs/vampire_2/vampire_2.tres"),
	EnemySkin.VampireRed: preload("res://assets/shared/characters/mobs/vampire_3/vampire_3.tres")
}

@export var skin: EnemySkin = EnemySkin.VampireGreen:
	set(value):
		skin = value
		_update_skin()

func _update_skin() -> void:
	if not is_node_ready() and Engine.is_editor_hint():
		await ready
	if _sprite and SKIN_TEXTURES.has(skin):
		_sprite.sprite_frames = SKIN_TEXTURES[skin]
		_sprite.play("idle_down")

#endregion
