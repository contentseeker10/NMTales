extends Node


func entry_location(location_name: String) -> void:
	print("Loading location " + location_name + "...")
	
	var local_pack_path: String = "user://" + location_name.to_lower() + ".pck"
	var scene_path: String = "res://locations/" + location_name.to_lower() + "/" + location_name.to_lower() + ".tscn"
	
	if ResourceLoader.exists(scene_path):
		print("Location was found in game files.")
		print("Skipping downloading and mounting.")
		get_tree().change_scene_to_file(scene_path)
		return
	
	if FileAccess.file_exists(local_pack_path):
		print("Location pack was found locally.")
		print("Proceeding to mounting.")
		_mount_pack(local_pack_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Location pack was not found locally.")
		print("Proceeding to downloading.")
		if await NetworkManager.download_pack(NetworkManager.PackType.LOCATION, location_name, local_pack_path):
			_mount_pack(local_pack_path)
			get_tree().change_scene_to_file(scene_path)
		else:
			print("Unable to entry location.")

func _mount_pack(pack_path: String) -> void:
	var success: bool = ProjectSettings.load_resource_pack(pack_path)
	if success:
		print("Pack was successfully mounted from user://")
	else:
		push_error("Error mounting pack " + pack_path)
