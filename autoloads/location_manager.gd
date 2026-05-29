extends Node


func entry_location(location_name: String) -> void:
	print("Loading location " + location_name + "...")
	
	var local_pack_path: String = "user://" + location_name.to_lower() + ".pck"
	var scene_path: String = "res://locations/" + location_name.to_lower() + "/" + location_name.to_lower() + ".tscn"
	
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		return
	
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
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Unable to entry location.")


func spawn_player(point: Node2D) -> void:
	var player: Player = preload("res://parts/player/player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	player.global_position = point.global_position
