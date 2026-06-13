extends Node

var target_spawn_point_id: String = "start"

var current_location: String


func entry_location(location_name: String) -> void:
	print("Loading location " + location_name + "...")
	
	var local_pack_path: String = "user://" + location_name.to_lower() + ".pck"
	var scene_path: String = "res://locations/" + location_name.to_lower() + "/" + location_name.to_lower() + ".scn"
	
	if ResourceLoader.exists(scene_path):
		print("Location exists. Loading.")
		get_tree().change_scene_to_file(scene_path)
		current_location = location_name
		return
	
	print("Downloading location from server...")
	
	if FileAccess.file_exists(local_pack_path):
		if PackManager.mount_pack(local_pack_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			_try_download_location(location_name, local_pack_path, scene_path)
	else:
		_try_download_location(location_name, local_pack_path, scene_path)

func _try_download_location(location_name: String, target_path: String, scene_path: String) -> void:
	if await NetworkManager.download_pack(PackManager.PackType.LOCATION, location_name, target_path):
		PackManager.mount_pack(target_path)
		current_location = location_name
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Unable to entry location.")


func update_player_location(location_name: String, player_coords: Vector2) -> void:
	var body: Dictionary = {
		"currentLocation": location_name,
		"currentPositionX": player_coords.x,
		"currentPositionY": player_coords.y
	}
	NetworkManager.send_post("/api/Player/location", body, AuthManager.token_header)


func spawn_player() -> Player:
	var player: Player = preload("res://parts/player/player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	player.global_position = _get_spawn_point().global_position
	target_spawn_point_id = "start"
	return player


func init_start_spawn() -> void:
	var start_spawn: SpawnPoint = get_tree().current_scene.get_node("PlayerSpawnPoints/Start")
	var spawnX: int = AuthManager.current_user_info.get("currentPositionX", 0)
	var spawnY: int = AuthManager.current_user_info.get("currentPositionY", 0)
	start_spawn.global_position = Vector2(spawnX, spawnY)


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
