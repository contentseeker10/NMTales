extends Node2D

@export var math_ui_scene: PackedScene

var is_available: bool = false


func _on_interaction_area_body_entered(_body: Node2D) -> void:
	is_available = true


func _on_interaction_area_body_exited(_body: Node2D) -> void:
	is_available = false


func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_available and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
		and event.is_pressed():
			var math_ui: CanvasLayer = math_ui_scene.instantiate()
			get_tree().current_scene.add_child(math_ui)
