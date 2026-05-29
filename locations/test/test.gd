extends Node2D

@export var spawn_point: Marker2D

func _ready() -> void:
	LocationManager.spawn_player(spawn_point)
