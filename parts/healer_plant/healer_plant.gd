class_name HealerPlant
extends Area2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var is_available: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	var click_area = get_node_or_null("ClickArea")
	if click_area:
		click_area.input_event.connect(_on_input_event)


func _on_body_entered(body: Node2D) -> void:
	if body and body is Player:
		is_available = true


func _on_body_exited(body: Node2D) -> void:
	if body and body is Player:
		is_available = false


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		_trigger_heal()


func _trigger_heal() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(player):
		return
	
	var body = {
		"plantId": name,
		"positionX": global_position.x,
		"positionY": global_position.y
	}
	
	var request = NetworkManager.send_post("/api/combat/heal", body, AuthManager.token_header)
	if request:
		var response = await request.request_completed
		request.queue_free()
		
		if response[1] == 200:
			var response_body: String = response[3].get_string_from_utf8()
			var data: Dictionary = JSON.parse_string(response_body)
			if data:
				player.health_points = data.get("currentHp", player.health_points)
				_play_heal_effect(player)
				queue_free()


func _play_heal_effect(player: Player) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 0.5
	particles.amount = 15
	particles.direction = Vector2.UP
	particles.spread = 45.0
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.color = Color.GREEN
	particles.position = Vector2.ZERO
	player.add_child(particles)
	
	var timer := Timer.new()
	particles.add_child(timer)
	timer.wait_time = 0.6
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	timer.start()
