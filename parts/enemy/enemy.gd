@tool
class_name Enemy
extends CharacterBody2D

#region Node imports

@onready var _attack_area: Area2D = $AttackArea
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _path_timer: Timer = $PathTimer

#endregion

var _player: Player

enum State { CHASE, ATTACK, DEAD }
var current_state: State = State.CHASE

@export var speed: int = 150
@export_range(0.0, 80.0, 5.0) var damage: int = 10

const GROWLS: Array[AudioStream] = [
	preload("res://assets/shared/audio/enemy/Warg_Growl.wav"),
	preload("res://assets/shared/audio/enemy/Warg_Growl2.wav")
]

const DEATH_SOUNDS: Array[AudioStream] = [
	preload("res://assets/shared/audio/enemy/Warg_Talk.wav"),
	preload("res://assets/shared/audio/enemy/Warg_Talk2.wav")
]


func _ready() -> void:
	_path_timer.timeout.connect(_on_path_timer_timeout)
	_update_skin()


func _physics_process(_delta: float) -> void:
	
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		if not is_instance_valid(_player):
			return
	
	match current_state:
		State.CHASE:
			_process_chase()
		State.ATTACK, State.DEAD:
			pass


#region State processing

func _process_chase() -> void:
	for body in _attack_area.get_overlapping_bodies():
		if body is Player:
			_start_attack()
			return
	
	if _nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	
	var next_position := _nav_agent.get_next_path_position()
	var direction := (next_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	sprite.play("walk_" + _get_direction_name(velocity))

func _on_path_timer_timeout() -> void:
	if is_instance_valid(_player):
		_nav_agent.target_position = _player.global_position


func _start_attack() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	
	if not Engine.is_editor_hint():
		var sfx = GROWLS[randi() % GROWLS.size()]
		AudioManager.play_sfx_2d(sfx, global_position, 0.1, "SFX")
	
	var dir_to_player := _player.global_position - global_position
	sprite.play("attack_" + _get_direction_name(dir_to_player))
	
	await sprite.animation_finished
	
	if current_state != State.ATTACK:
		return
	
	if _player in _attack_area.get_overlapping_bodies():
		var request: HTTPRequest = NetworkManager.send_post("/api/combat/damage", { "amount": damage }, AuthManager.token_header)
		if request:
			var response: Array = await request.request_completed
			request.queue_free()
			
			if response[1] == 200:
				var response_body: String = response[3].get_string_from_utf8()
				var data: Dictionary = JSON.parse_string(response_body)
				if data and is_instance_valid(_player):
					_player.update_health_from_server(data.get("currentHp", 0), data.get("isDead", false))
	
	current_state = State.CHASE


func set_dead() -> void:
	current_state = State.DEAD
	
	if not Engine.is_editor_hint():
		var sfx = DEATH_SOUNDS[randi() % DEATH_SOUNDS.size()]
		AudioManager.play_sfx_2d(sfx, global_position, 0.1, "SFX")
	
	collision_layer = 0
	collision_mask = 0
	
	_attack_area.monitoring = false
	_attack_area.monitorable = false
	
	sprite.play("death_down")
	await sprite.animation_finished
	queue_free()


func _get_direction_name(vel: Vector2) -> String:
	if vel.length_squared() < 10.0:
		return "down"
	var norm := vel.normalized()
	if abs(norm.x) > abs(norm.y):
		return "right" if norm.x > 0 else "left"
	else:
		return "down" if norm.y > 0 else "up"

#endregion


#region Skin changer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

enum EnemySkin { VampireGreen, VampireBlue, VampireRed }
const SKIN_TEXTURES := {
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
	if sprite and SKIN_TEXTURES.has(skin):
		sprite.sprite_frames = SKIN_TEXTURES[skin]
		sprite.play("idle_down")

#endregion
