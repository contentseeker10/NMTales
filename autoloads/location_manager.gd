## Autoload class that manages loading, downloading, and transitioning between game locations,
## as well as player spawning and reporting player location telemetry to the server.
extends Node

## The ID of the target spawn point where the player should spawn next (e.g. after transitioning).
var target_spawn_point_id: String = "start"

## The name of the currently loaded location.
var current_location: String


## Initiates transition to a new location.
## If the location scene exists locally, it transitions directly.
## Otherwise, it attempts to load/mount a local pack or download it from the server.
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


## Attempts to download the location pack from the server, mount it, and transition to the target scene.
func _try_download_location(location_name: String, target_path: String, scene_path: String) -> void:
	if await NetworkManager.download_pack(PackManager.PackType.LOCATION, location_name, target_path):
		PackManager.mount_pack(target_path)
		current_location = location_name
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Unable to entry location.")


## Updates and sends the player's current location and coordinates to the backend server.
func update_player_location(location_name: String, player_coords: Vector2) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player and player.is_dead:
		return
	var body: Dictionary = {
		"currentLocation": location_name,
		"currentPositionX": player_coords.x,
		"currentPositionY": player_coords.y
	}
	_send_coords(body)


## Sends the location coordinates payload to the server API asynchronously.
func _send_coords(body: Dictionary) -> void:
	var http_request := NetworkManager.send_post("/api/Player/location", body, AuthManager.token_header)
	await http_request.request_completed
	http_request.queue_free()


## Instantiates the player scene, adds it to the current scene tree, and positions it at the target spawn point.
## Also reports telemetry if spawning at a checkpoint and resets the spawn point ID back to default.
func spawn_player() -> Player:
	var player: Player = preload("res://parts/player/player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	var spawn_pt = _get_spawn_point()
	player.global_position = spawn_pt.global_position
	
	# Submit telemetry if spawning at a checkpoint/teleport point
	if spawn_pt.spawn_point_id != "start":
		AchievementsManager.submit_telemetry("SpawnPointUnlocked", spawn_pt.spawn_point_id)
		
	target_spawn_point_id = "start"
	return player


## Initializes the "Start" spawn point's coordinates based on the current user's location saved in user info.
func init_start_spawn() -> void:
	var start_spawn: SpawnPoint = get_tree().current_scene.get_node("PlayerSpawnPoints/Start")
	var spawnX: int = AuthManager.current_user_info.get("currentPositionX", 0)
	var spawnY: int = AuthManager.current_user_info.get("currentPositionY", 0)
	start_spawn.global_position = Vector2(spawnX, spawnY)


## Returns the SpawnPoint instance that matches the target spawn point ID.
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

