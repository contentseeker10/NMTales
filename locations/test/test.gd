extends Node2D

@onready var start_spawn: SpawnPoint = $PlayerSpawnPoints/Start
var player: Player


func _ready() -> void:
	EventBus.location_entered.emit("test")
	
	var spawnX: int = AuthManager.current_user_info.get("currentPositionX", 0)
	var spawnY: int = AuthManager.current_user_info.get("currentPositionY", 0)
	start_spawn.global_position = Vector2(spawnX, spawnY)
	player = LocationManager.spawn_player()
	LocationManager.target_spawn_point_id = "start"


func _process(_delta: float) -> void:
	LocationManager.update_player_location(LocationManager.current_location, player.global_position)
