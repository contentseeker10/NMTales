class_name Player
extends CharacterBody2D

#region Node imports

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: CanvasLayer = $HUD
@onready var attack_area: Area2D = $AttackArea

#endregion

var can_attack: bool = true

@export var speed: float = 150.0

signal health_changed(new_value: int)

var health_points: int = 80:
	set(value):
		health_points = clampi(value, 0, 80)
		health_changed.emit(health_points)


func _ready() -> void:
	hud.visible = true;


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.current_state = Enemy.State.DEAD
