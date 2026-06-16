## Represents the player character in the game.
##
## Handles player movement, health state, collision/combat logic with enemies,
## HUD synchronization, and server-side combat or respawn communications.
class_name Player
extends CharacterBody2D

#region Node imports

## The animated sprite showing the player's movements and animations.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
## The heads-up display showing player health, death screens, and UI elements.
@onready var hud: HUD = $HUD
## Area used to detect and collide with enemies during attacks.
@onready var attack_area: Area2D = $AttackArea

#endregion

## Whether the player can initiate an attack.
var can_attack: bool = true
## Player's death state. Modifying this triggers appropriate UI sound effects and resets velocity/sprite animations.
var is_dead: bool = false:
	set(value):
		var was_dead = is_dead
		is_dead = value
		if is_dead:
			velocity = Vector2.ZERO
			if sprite:
				sprite.play("idle_down")
			if not was_dead and is_node_ready():
				AudioManager.play_sfx(preload("res://assets/shared/audio/ui/played_died.wav"), 0.0, "SFX")
		elif was_dead:
			if is_node_ready():
				AudioManager.play_sfx(preload("res://assets/shared/audio/ui/player_revived.wav"), 0.0, "SFX")

## Movement speed of the player.
@export var speed: float = 150.0

## Current health points of the player. Clamped between 0 and 80.
## Updates the HUD and notifies the system of death if reaching 0.
var health_points: int:
	set(value):
		health_points = clampi(value, 0, 80)
		if hud and hud.is_node_ready():
			var health_bar := hud.get_node("MarginContainer/HealthBar") as HealthBar
			if health_bar:
				health_bar.update_health(health_points)
		if health_points == 0:
			EventBus.player_died.emit()


## Initializes the HUD, buttons, and loads initial state from AuthManager.
func _ready() -> void:
	hud.visible = true;
	hud.death_screen.revive_button.pressed.connect(_on_revive_button_pressed)
	
	var initial_hp = int(AuthManager.current_user_info.get("currentHp", 80))
	var initial_dead = bool(AuthManager.current_user_info.get("isDead", false))
	
	is_dead = initial_dead
	health_points = initial_hp
	if is_dead:
		EventBus.player_died.emit()


## Callback when a body enters the player's attack detection area.
## If the body is an Enemy, sets the enemy to dead and notifies EventBus.
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.set_dead()
		EventBus.mob_killed.emit("vampire")


## Updates the player's health points and dead state with values provided by the server.
func update_health_from_server(current_hp: int, is_dead_val: bool) -> void:
	health_points = current_hp
	is_dead = is_dead_val
	if is_dead:
		EventBus.player_died.emit()


## Sends an attack request to the backend server.
## Returns true if the attack request was successful (HTTP 200).
func request_attack() -> bool:
	var request: HTTPRequest = NetworkManager.send_post("/api/combat/attack", {}, AuthManager.token_header)
	if not request:
		return false
	var response: Array = await request.request_completed
	request.queue_free()
	
	return response[1] == 200


## Handles the response when the revive button is pressed, requesting a server-side respawn.
## Resets position, health, and UI state on success.
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


