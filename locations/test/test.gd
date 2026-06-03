extends Node2D

var player: Player


func _ready() -> void:
	EventBus.location_entered.emit("test")
	
	LocationManager.init_start_spawn()
	player = LocationManager.spawn_player()


func _process(_delta: float) -> void:
	LocationManager.update_player_location(LocationManager.current_location, player.global_position)
