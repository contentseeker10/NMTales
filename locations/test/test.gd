extends Node2D


func _ready() -> void:
	LocationManager.spawn_player()
	EventBus.location_entered.emit("test")
