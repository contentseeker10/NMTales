## A button that can be dragged by the mouse.
##
## When pressed, the button follows the mouse position and renders on top.
## When released, it returns to its initial position.
class_name DragButton
extends Button

## Area2D node used for collision/overlap detection.
@onready var area: Area2D = $Area2D
## The CollisionShape2D for the button's area, updated to match its size.
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

## Unique identifier for the drag button, useful for identifying the dragged item.
@export var id: int = 0

## The initial position of the button before dragging started.
var init_pos: Vector2


func _ready() -> void:
	await get_tree().process_frame
	_update_collision()
	init_pos = self.position


## Generates and updates a RectangleShape2D to match the current button size,
## and centers the collision shape accordingly.
func _update_collision() -> void:
	var new_shape: RectangleShape2D = RectangleShape2D.new()
	new_shape.size = self.size
	collision.shape = new_shape
	collision.position = self.size / 2


func _process(_delta: float) -> void:
	if button_pressed:
		self.top_level = true
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		self.global_position = Vector2(mouse_pos.x - self.size.x / 2, mouse_pos.y - self.size.y / 2)
	else:
		self.top_level = false
		self.position = init_pos

