extends Node

var target_spawn_point_id: String = "start"


func entry_location(location_name: String) -> void:
	print("Loading location " + location_name + "...")
	
	var local_pack_path: String = "user://" + location_name.to_lower() + ".pck"
	var scene_path: String = "res://locations/" + location_name.to_lower() + "/" + location_name.to_lower() + ".tscn"
	
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		_update_player_location(location_name, Vector2.ZERO)
		return
	
	if FileAccess.file_exists(local_pack_path):
		if PackManager.mount_pack(local_pack_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			_try_download_location(location_name, local_pack_path, scene_path)
			_update_player_location(location_name, Vector2.ZERO)
	else:
		_try_download_location(location_name, local_pack_path, scene_path)
		_update_player_location(location_name, Vector2.ZERO)

func _try_download_location(location_name: String, target_path: String, scene_path: String) -> void:
	if await NetworkManager.download_pack(PackManager.PackType.LOCATION, location_name, target_path):
		PackManager.mount_pack(target_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Unable to entry location.")


func _update_player_location(location_name: String, player_coords: Vector2) -> void:
	var body: Dictionary = {
		"currentLocation": location_name,
		"currentPositionX": player_coords.x,
		"currentPositionY": player_coords.y
	}
	NetworkManager.send_post("/api/Player/location", body, AuthManager.token_header)


func spawn_player(coords: Vector2 = Vector2.INF) -> void:
	var player: Player = preload("res://parts/player/player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	if coords != Vector2.INF:
		player.global_position = coords
	else:
		player.global_position = _get_spawn_point().global_position


func _get_spawn_point() -> SpawnPoint:
	var spawn_points: Array
	
	if get_tree().current_scene.has_node("PlayerSpawnPoints"):
		spawn_points = get_tree().current_scene.get_node("PlayerSpawnPoints").get_children()
	else:
		push_error("Location needs player spawn points list.")
	
	for point in spawn_points:
		if point.spawn_point_id == target_spawn_point_id:
			return point
	
	push_error("No such spawn point.")
	return null
