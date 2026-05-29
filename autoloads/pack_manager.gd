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


func mount_pack(pack_path: String) -> bool:
	var success: bool = ProjectSettings.load_resource_pack(pack_path)
	if success:
		return true
	else:
		DirAccess.remove_absolute(pack_path)
		return false
