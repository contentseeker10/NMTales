class_name Player
extends CharacterBody2D

#region Node imports

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: HUD = $HUD
@onready var attack_area: Area2D = $AttackArea

#endregion

var can_attack: bool = true
var is_dead: bool = false:
	set(value):
		is_dead = value
		if is_dead:
			velocity = Vector2.ZERO
			if sprite:
				sprite.play("idle_down")

@export var speed: float = 150.0

var health_points: int:
	set(value):
		health_points = clampi(value, 0, 80)
		if hud and hud.is_node_ready():
			var health_bar := hud.get_node("MarginContainer/HealthBar") as HealthBar
			if health_bar:
				health_bar.update_health(health_points)
		if health_points == 0:
			EventBus.player_died.emit()


func _ready() -> void:
	hud.visible = true;
	hud.death_screen.revive_button.pressed.connect(_on_revive_button_pressed)
	
	var initial_hp = int(AuthManager.current_user_info.get("currentHp", 80))
	var initial_dead = bool(AuthManager.current_user_info.get("isDead", false))
	
	is_dead = initial_dead
	health_points = initial_hp
	if is_dead:
		EventBus.player_died.emit()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.set_dead()
		EventBus.mob_killed.emit("vampire")


func update_health_from_server(current_hp: int, is_dead_val: bool) -> void:
	health_points = current_hp
	is_dead = is_dead_val
	if is_dead:
		EventBus.player_died.emit()


func request_attack() -> bool:
	var request: HTTPRequest = NetworkManager.send_post("/api/combat/attack", {}, AuthManager.token_header)
	if not request:
		return false
	var response: Array = await request.request_completed
	request.queue_free()
	
	return response[1] == 200


func _on_revive_button_pressed() -> void:
	var request: HTTPRequest = NetworkManager.send_post("/api/combat/respawn", {}, AuthManager.token_header)
	if not request:
		return
	var response: Array = await request.request_completed
	request.queue_free()
	
	if response[1] == 200:
		var response_body: String = response[3].get_string_from_utf8()
		var data: Dictionary = JSON.parse_string(response_body)
		if data:
			is_dead = false
			global_position = Vector2(data.get("positionX", 0.0), data.get("positionY", 0.0))
			health_points = data.get("currentHp", 20)
			hud.death_screen.hide()

