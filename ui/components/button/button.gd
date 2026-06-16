## A custom button component that handles screen transitions.
##
## This button extends the base [Button] to transition the current scene
## to a predefined target scene upon interaction.
extends Button


## Callback function triggered when the button is pressed.
## Transitions the active scene to the simple tile map scene.
func on_pressed():
	get_tree().change_scene_to_file("res://simple_tile_map.tscn")

