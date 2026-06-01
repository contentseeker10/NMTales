extends Button


# Called when the node enters the scene tree for the first time.
func on_pressed():
	get_tree().change_scene_to_file("res://simple_tile_map.tscn")
