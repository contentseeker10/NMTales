class_name Player extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: CanvasLayer = $HUD

@export_range(0, 100, 5) var health: int = 100
@export var speed: float = 150.0

func _ready() -> void:
	hud.visible = true
