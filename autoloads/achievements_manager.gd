extends Node

const NOTIFICATION_SCENE: PackedScene = preload("res://ui/components/notification/notification.tscn")

func _ready() -> void:
	EventBus.mob_killed.connect(_on_mob_killed)
	EventBus.player_died.connect(_on_player_died)


func _on_mob_killed(mob_id: String) -> void:
	if mob_id == "vampire":
		submit_telemetry("VampireKill", "")


func _on_player_died() -> void:
	submit_telemetry("PlayerDeath", "")


func fetch_achievements() -> Array:
	var response: Array = await NetworkManager.send_get("/api/achievement", AuthManager.token_header)
	var status: int = response[1]
	var body: String = response[3].get_string_from_utf8()
	
	if status != 200:
		printerr("Failed to fetch achievements. Status: ", status)
		return []
		
	var data: Variant = JSON.parse_string(body)
	if data is Array:
		return data
	return []


func submit_telemetry(event_type: String, event_detail: String) -> void:
	var body: Dictionary = {
		"eventType": event_type,
		"eventDetail": event_detail
	}
	var request: HTTPRequest = NetworkManager.send_post("/api/achievement/event", body, AuthManager.token_header)
	if not request:
		printerr("Failed to submit telemetry event.")
		return
		
	var response: Array = await request.request_completed
	request.queue_free()
	
	var status: int = response[1]
	var response_body: String = response[3].get_string_from_utf8()
	
	if status != 200:
		printerr("Telemetry event submission failed. Status: ", status, " Body: ", response_body)
		return
		
	var new_unlocks: Variant = JSON.parse_string(response_body)
	if new_unlocks is Array and not new_unlocks.is_empty():
		await _handle_new_unlocks(new_unlocks)


func _handle_new_unlocks(new_unlocks: Array) -> void:
	var target_parent: Node = null
	if get_tree().current_scene:
		target_parent = get_tree().current_scene.get_node_or_null("HUD")
		if not target_parent:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_node("HUD"):
				target_parent = player.get_node("HUD")
			else:
				target_parent = get_tree().current_scene
				
	if not target_parent:
		printerr("No active scene or HUD to display unlock notifications.")
		return
		
	for ach in new_unlocks:
		var title = ach.get("title", "")
		var xpReward = ach.get("xpReward", 0)
		var notif: Notification = NOTIFICATION_SCENE.instantiate()
		target_parent.add_child(notif)
		await notif.show_notification("Досягнення отримано: " + title + "! (+" + str(xpReward) + " XP)")
		notif.queue_free()
		
	# Trigger HUD level and XP progression update
	var hud: HUD = target_parent if target_parent is HUD else null
	if not hud:
		if get_tree().current_scene:
			hud = get_tree().current_scene.get_node_or_null("HUD") as HUD
			if not hud:
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_node("HUD"):
					hud = player.get_node("HUD") as HUD
					
	if hud and hud.has_method("_update_level_progression"):
		hud._update_level_progression()
