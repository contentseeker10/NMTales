class_name Player extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: CanvasLayer = $HUD

@export var speed: float = 150.0

var can_attack: bool = true

func _ready() -> void:
	hud.visible = true;
