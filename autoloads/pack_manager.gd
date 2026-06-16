## Manager for loading and handling external resource packs (PCKs/ZIPs).
##
## This autoload handles mounting resource packs (like location or quest packs)
## dynamically at runtime.
extends Node

## Types of content packs that can be managed.
enum PackType {
	## Pack containing location/map assets and scenes.
	LOCATION,
	## Pack containing quest data, scripts, and related dialogue.
	QUEST
}


## Returns the string representation of a [enum PackType].
func get_pack_type(pack_type: PackType) -> String:
	match pack_type:
		PackType.LOCATION:
			return "Location"
		PackType.QUEST:
			return "Quest"
	return ""


## Mounts a resource pack from the given [param pack_path].
## If mounting fails, the pack file is deleted from the filesystem.
## Returns [code]true[/code] if successful, [code]false[/code] otherwise.
func mount_pack(pack_path: String) -> bool:
	var success: bool = ProjectSettings.load_resource_pack(pack_path)
	if success:
		return true
	else:
		DirAccess.remove_absolute(pack_path)
		return false
