## A UI component representing a target drop area for drag-and-drop operations.
##
## This component manages collision detection with draggable buttons,
## snaps them into place when dropped, and allows checking correctness.
class_name DropArea
extends PanelContainer

#region Node imports

## The button representing the switch/toggle state of this drop area.
@onready var switch: Button = $Switch
## The Area2D used to detect overlapping draggable items.
@onready var active_area: Area2D = $ActiveArea
## The container holding the currently snapped DragButton.
@onready var active_container: CenterContainer = $MarginContainer/ActiveContainer

#endregion

#region Vault-variables

## The index of this drop area, typically used for matching or sequencing.
var index: int

## The currently snapped DragButton inside this drop area, if any.
var drag_button: DragButton
## The DragButton currently overlapping this drop area's active region.
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

## Snaps the specified [param parent] DragButton to this drop area.
##
## Duplicates the drag button, places it inside the active container,
## frees the original, and updates collision states.
func _snap_button(parent: DragButton) -> void:
	drag_button = parent.duplicate()
	active_container.add_child(drag_button)
	
	drag_button.top_level = false
	drag_button.button_pressed = false
	
	parent.queue_free()
	switch.button_pressed = true
	_set_area_state(false)
	overlap_button = null


## Unsnaps the current button, clearing references and updating switch state.
func _unsnap_button() -> void:
	drag_button = null
	switch.button_pressed = false


## Toggles collision masks to activate or deactivate the drop detection area.
func _set_area_state(active: bool) -> void:
	if not active_area:
		return
	active_area.set_collision_mask_value(1, active)
	active_area.set_collision_mask_value(2, not active)

#endregion


#region Signals processing

## Triggered when an area enters the active drop detection zone.
func _on_active_area_area_entered(area: Area2D) -> void:
	var parent: DragButton = area.get_parent() as DragButton
	if parent and not switch.button_pressed:
		overlap_button = parent


## Triggered when an area leaves the active drop detection zone.
func _on_active_area_area_exited(area: Area2D) -> void:
	var parent: DragButton = area.get_parent() as DragButton
	if parent and parent == overlap_button:
		overlap_button = null


## Callback for when the switch button is toggled.
func _on_switch_toggled(toggled_on: bool) -> void:
	_set_area_state(not toggled_on)

#endregion


## Visualizes correctness by overlaying a green or red [ColorRect].
func mark_correct(is_correct: bool) -> void:
	var marker: ColorRect = ColorRect.new()
	if is_correct:
		marker.color = Color.from_rgba8(0, 200, 60, 100)
	else:
		marker.color = Color.from_rgba8(200, 0, 0, 100)
	self.add_child(marker)
