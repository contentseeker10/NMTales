## The main game location controller.
##
## Manages the setup, player spawning, background music playback,
## and periodic updates of the player's position for the "main" location.
class_name MainLocation
extends Node2D

## The Player instance spawned in this location.
var player: Player

## Timer used to trigger periodic player position updates.
var _timer: Timer


## Called when the node enters the scene tree.
## Initializes the location entrance event, spawns the player,
## plays the background music, and starts tracking the player's location.
func _ready() -> void:
	EventBus.location_entered.emit("main")
	
	LocationManager.init_start_spawn()
	player = LocationManager.spawn_player()
	
	AudioManager.play_music(preload("res://assets/shared/audio/music/2. Winds of Valor.wav"))
	_process_player_location()


## Periodically reports the player's position to the LocationManager.
## Runs a loop that waits for the timer to timeout and updates coordinates.
func _process_player_location() -> void:
	_init_timer(0.5)
	while true:
		await _timer.timeout
		LocationManager.update_player_location(LocationManager.current_location, player.global_position)


## Initializes and starts a timer with the given [param wait_time].
func _init_timer(wait_time: float) -> void:
	_timer = Timer.new()
	_timer.wait_time = wait_time
	_timer.autostart = true
	add_child(_timer)

