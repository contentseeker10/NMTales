class_name DragButton
extends Button

@onready var area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

var id: int

var init_pos: Vector2


func _ready() -> void:
	await get_tree().process_frame
	_update_collision()
	init_pos = self.position

func _update_collision() -> void:
	var new_shape: RectangleShape2D = RectangleShape2D.new()
	new_shape.size = self.size
	collision.shape = new_shape
	collision.position = self.position + (self.size / 2)


func _process(_delta: float) -> void:
	if button_pressed:
		self.top_level = true
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		self.global_position = Vector2(mouse_pos.x - self.size.x / 2, mouse_pos.y - self.size.y / 2)
	else:
		self.top_level = false
		self.position = init_pos
