class_name Player
extends CharacterBody2D

#region Node imports

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud: HUD = $HUD
@onready var attack_area: Area2D = $AttackArea

#endregion

var can_attack: bool = true

@export var speed: float = 150.0

var health_points: int:
	set(value):
		health_points = clampi(value, 0, 80)
		if hud and hud.is_node_ready():
			var health_bar := hud.get_node("MarginContainer/HealthBar") as HealthBar
			if health_bar:
				health_bar.update_health(health_points)
		if health_points == 0:
			EventBus.player_died.emit()


func _ready() -> void:
	health_points = 80
	hud.visible = true;
	hud.death_screen.revive_button.pressed.connect(_on_revive_button_pressed)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.set_dead()
		EventBus.mob_killed.emit("vampire")


func _on_revive_button_pressed() -> void:
	_revive()
	hud.death_screen.hide()
	get_tree().paused = false


func _revive() -> void:
	health_points = 80
	global_position = Vector2.ZERO
