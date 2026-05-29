extends Node

enum PackType {
	LOCATION,
	QUEST
}

func get_pack_type(pack_type: PackType) -> String:
	match pack_type:
		PackType.LOCATION:
			return "Location"
		PackType.QUEST:
			return "Quest"
	return ""


func entry_location(location_name: String) -> void:
	print("Loading location " + location_name + "...")
	
	var local_pack_path: String = "user://" + location_name.to_lower() + ".pck"
	var scene_path: String = "res://locations/" + location_name.to_lower() + "/" + location_name.to_lower() + ".tscn"
	
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		return
	
	if FileAccess.file_exists(local_pack_path):
		if _mount_pack(local_pack_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			_try_download_location(location_name, local_pack_path, scene_path)
	else:
		_try_download_location(location_name, local_pack_path, scene_path)

func _try_download_location(location_name: String, target_path: String, scene_path: String) -> void:
	if await NetworkManager.download_pack(PackManager.PackType.LOCATION, location_name, target_path):
		_mount_pack(target_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Unable to entry location.")

func _mount_pack(pack_path: String) -> bool:
	var success: bool = ProjectSettings.load_resource_pack(pack_path)
	if success:
		return true
	else:
		DirAccess.remove_absolute(pack_path)
		return false
