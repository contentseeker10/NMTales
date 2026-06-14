class_name MainLocation
extends Node2D

var player: Player

var _timer: Timer

func _ready() -> void:
	EventBus.location_entered.emit("main")
	
	LocationManager.init_start_spawn()
	player = LocationManager.spawn_player()
	
	_process_player_location()


func _process_player_location() -> void:
	_init_timer(0.5)
	while true:
		await _timer.timeout
		LocationManager.update_player_location(LocationManager.current_location, player.global_position)

func _init_timer(wait_time: float) -> void:
	_timer = Timer.new()
	_timer.wait_time = wait_time
	_timer.autostart = true
	add_child(_timer)
