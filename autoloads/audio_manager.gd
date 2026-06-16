extends Node

## Universal and Flexible Audio System for NMTales
## Manages BGM (crossfading), SFX (polyphonic pool, pitch variance), and auto UI sound hooks.

@export var auto_ui_sounds: bool = true

# Store default streams (Developer can replace these streams in Godot or via code)
@export var default_click_sfx: AudioStream = preload("res://assets/shared/audio/ui/player_answered.wav")
@export var default_hover_sfx: AudioStream = preload("res://assets/shared/audio/ui/standart_ui_hover.wav")

var _music_players: Array[AudioStreamPlayer] = []
var _active_music_player_idx: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 1. Initialize two music players for smooth BGM crossfading
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		_music_players.append(player)
		
	# 2. Wire up global UI node additions for auto-button sounds if enabled
	if auto_ui_sounds:
		get_tree().node_added.connect(_on_node_added)


## Plays background music with smooth crossfading.
## Passing a null stream will fade out the current music and stop it.
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var current_player: AudioStreamPlayer = null
	if _active_music_player_idx != -1:
		current_player = _music_players[_active_music_player_idx]
		
	if stream == null:
		stop_music(fade_duration)
		return
		
	if current_player and current_player.stream == stream:
		if not current_player.playing:
			current_player.play()
		return
		
	var next_player_idx: int = 1 if _active_music_player_idx == 0 else 0
	var next_player: AudioStreamPlayer = _music_players[next_player_idx]
	
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(next_player, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if current_player:
		tween.tween_property(current_player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	_active_music_player_idx = next_player_idx
	
	# Stop the previous music player after the fade out completes
	tween.chain().set_parallel(false)
	if current_player:
		tween.tween_callback(current_player.stop)


## Stops current background music with a fade out.
func stop_music(fade_duration: float = 1.0) -> void:
	if _active_music_player_idx == -1:
		return
		
	var current_player = _music_players[_active_music_player_idx]
	if current_player and current_player.playing:
		var tween = create_tween()
		tween.tween_property(current_player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(current_player.stop)
		
	_active_music_player_idx = -1


## Plays a non-spatial sound effect with optional pitch randomization to prevent repetition.
func play_sfx(stream: AudioStream, pitch_variance: float = 0.08, bus: String = "SFX") -> AudioStreamPlayer:
	if stream == null:
		return null
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	
	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
		
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player


## Plays a 2D spatial sound effect at a given position.
func play_sfx_2d(stream: AudioStream, global_pos: Vector2, pitch_variance: float = 0.08, bus: String = "SFX") -> AudioStreamPlayer2D:
	if stream == null:
		return null
		
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = global_pos
	player.bus = bus
	
	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
		
	var target_parent = get_tree().current_scene
	if not target_parent:
		target_parent = self
		
	target_parent.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
	return player


## Recursively registers button hover and pressed sounds on a specific UI tree branch.
## Useful if auto_ui_sounds is false or if manual setup is preferred.
func register_ui_sounds(node: Node) -> void:
	if node is BaseButton:
		_connect_button_signals(node)
	for child in node.get_children():
		register_ui_sounds(child)


# Helper to connect signals to buttons safely without duplicates
func _connect_button_signals(btn: BaseButton) -> void:
	if not btn.mouse_entered.is_connected(_on_button_hover):
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
	if not btn.focus_entered.is_connected(_on_button_hover):
		btn.focus_entered.connect(_on_button_hover.bind(btn))
	if not btn.pressed.is_connected(_on_button_click):
		btn.pressed.connect(_on_button_click.bind(btn))


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		# Defer to ensure metadata is fully loaded first
		_connect_button_signals.call_deferred(node)


func _on_button_hover(btn: BaseButton) -> void:
	if btn.disabled:
		return
	var sfx = btn.get_meta("hover_sfx", default_hover_sfx) as AudioStream
	if sfx:
		play_sfx(sfx, 0.05, "SFX")


func _on_button_click(btn: BaseButton) -> void:
	if btn.disabled:
		return
	var sfx = btn.get_meta("click_sfx", default_click_sfx) as AudioStream
	if sfx:
		play_sfx(sfx, 0.05, "SFX")


# ----- Volume / Mute Controls Helpers (dB to Linear converters) -----

func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var clamped = clampf(linear_volume, 0.0, 1.0)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamped))
	else:
		push_warning("Audio bus not found: " + bus_name)


func get_bus_volume(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	push_warning("Audio bus not found: " + bus_name)
	return 0.0


func set_bus_mute(bus_name: String, is_muted: bool) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_muted)
	else:
		push_warning("Audio bus not found: " + bus_name)


func is_bus_muted(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_mute(bus_idx)
	push_warning("Audio bus not found: " + bus_name)
	return false
