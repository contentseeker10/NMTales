class_name DropArea
extends PanelContainer

#region Node imports

@onready var switch: Button = $Switch
@onready var active_area: Area2D = $ActiveArea
@onready var active_container: CenterContainer = $MarginContainer/ActiveContainer

#endregion

#region Vault-variables

var index: int

var drag_button: DragButton
var overlap_button: DragButton

#endregion
 

#region Logic processing

func _ready() -> void:
	_set_area_state(not switch.button_pressed)
	if active_container.get_child_count() > 0:
		drag_button = active_container.get_child(0) as DragButton


func _process(_delta: float) -> void:
	if overlap_button and not overlap_button.button_pressed and not switch.button_pressed:
		_snap_button(overlap_button)
	if active_container.get_child_count() < 1:
		_unsnap_button()

#endregion


#region Snapping logic

func _snap_button(parent: DragButton) -> void:
	drag_button = parent.duplicate()
	active_container.add_child(drag_button)
	
	drag_button.top_level = false
	drag_button.button_pressed = false
	
	parent.queue_free()
	switch.button_pressed = true
	_set_area_state(false)
	overlap_button = null


func _unsnap_button() -> void:
	drag_button = null
	switch.button_pressed = false


func _set_area_state(active: bool) -> void:
	if not active_area:
		return
	active_area.set_collision_mask_value(1, active)
	active_area.set_collision_mask_value(2, not active)

#endregion


#region Signals processing

func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent: DragButton = area.get_parent() as DragButton
	if parent and not switch.button_pressed:
		overlap_button = parent


func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent: DragButton = area.get_parent() as DragButton
	if parent and parent == overlap_button:
		overlap_button = null


func _on_switch_toggled(toggled_on: bool) -> void:
	_set_area_state(not toggled_on)

#endregion
