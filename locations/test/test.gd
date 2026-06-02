extends Node2D


func _ready() -> void:
	EventBus.location_entered.emit("test")
	
	var playerX: int = AuthManager.current_user_info.get("currentPositionX", 0)
	var playerY: int = AuthManager.current_user_info.get("currentPositionY", 0)
	var coords: Vector2 = Vector2(playerX, playerY)
	LocationManager.spawn_player(coords)
