## A teleporter node that transitions the player to a target location and spawn point when clicked.
extends Node2D

## The Area2D used to detect the player and handle mouse clicks.
@onready var interaction_area: Area2D = $InteractionArea

## The path or identifier of the target location scene to load.
@export var target_location: String
## The identifier of the specific spawn point within the target location.
@export var target_spawn_point_id: String

## Tracks whether the player is within range to interact with the teleporter.
var is_available: bool = false


## Triggered when a body enters the interaction area, marking the teleporter as available.
func _on_interaction_area_body_entered(_body: Node2D) -> void:
	is_available = true

## Triggered when a body exits the interaction area, marking the teleporter as unavailable.
func _on_interaction_area_body_exited(_body: Node2D) -> void:
	is_available = false
	
## Handles mouse inputs on the interaction area and triggers teleportation if clicked while available.
func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
		_teleport_to(target_location)

## Configures the target spawn point and transitions the location via LocationManager.
func _teleport_to(location: String) -> void:
	LocationManager.target_spawn_point_id = target_spawn_point_id
	LocationManager.entry_location(location)

