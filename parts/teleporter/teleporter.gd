extends Node2D

@onready var interaction_area: Area2D = $InteractionArea

@export var target_location: String

var is_available: bool = false


func _on_interaction_area_body_entered(_body: Node2D) -> void:
	is_available = !is_available

func _on_interaction_area_body_exited(_body: Node2D) -> void:
	is_available = !is_available
	
func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
		_teleport_to(target_location)

func _teleport_to(location: String) -> void:
	LocationManager.entry_location(location)
