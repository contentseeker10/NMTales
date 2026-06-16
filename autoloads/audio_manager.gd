## Universal and Flexible Audio System for NMTales.
##
## Manages background music (BGM) crossfading, a sound effects (SFX) polyphonic pool
## with pitch variance, and auto-hooking of UI sounds for buttons.
extends Node

## If true, automatically hooks hover and click sounds to newly added UI buttons in the scene tree.
@export var auto_ui_sounds: bool = true

## Default sound effect to play when a UI button is clicked/pressed.
@export var default_click_sfx: AudioStream = preload("res://assets/shared/audio/ui/player_answered.wav")

## Default sound effect to play when a UI button is hovered or focused.
@export var default_hover_sfx: AudioStream = preload("res://assets/shared/audio/ui/standart_ui_hover.wav")

# Store default streams (Developer can replace these streams in Godot or via code)
var _music_players: Array[AudioStreamPlayer] = []
var _active_music_player_idx: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("[AudioManager] Initializing...")
	# 1. Initialize two music players for smooth BGM crossfading
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		_music_players.append(player)
		print("[AudioManager] Created music player %d on bus %s" % [i, player.bus])
		
	# 2. Wire up global UI node additions for auto-button sounds if enabled
	if auto_ui_sounds:
		get_tree().node_added.connect(_on_node_added)
		print("[AudioManager] Auto UI sounds enabled, node_added connected")


## Plays background music with smooth crossfading.
##
## [param stream] The AudioStream to play. If null, fades out and stops current music.
## [param fade_duration] The duration of the crossfade transition in seconds.
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	print("[AudioManager] play_music called with stream: %s, fade_duration: %.2f" % [str(stream), fade_duration])
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= 0:
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		print("[AudioManager] Stream is AudioStreamWAV, loop_mode set to: %d, loop_end set to: %d" % [stream.loop_mode, stream.loop_end])

	var current_player: AudioStreamPlayer = null
	if _active_music_player_idx != -1:
		current_player = _music_players[_active_music_player_idx]
		print("[AudioManager] Current active player index: %d, playing: %s, volume_db: %.2f" % [_active_music_player_idx, str(current_player.playing), current_player.volume_db])
		
	if stream == null:
		print("[AudioManager] Stream is null, stopping music")
		stop_music(fade_duration)
		return
		
	if current_player and current_player.stream == stream:
		print("[AudioManager] Current player already has this stream. Playing status: %s" % str(current_player.playing))
		if not current_player.playing:
			current_player.play()
			print("[AudioManager] Started playing existing stream")
		return
		
	var next_player_idx: int = 1 if _active_music_player_idx == 0 else 0
	var next_player: AudioStreamPlayer = _music_players[next_player_idx]
	
	next_player.stream = stream
	next_player.volume_db = -80.0
	print("[AudioManager] Playing next stream on player %d, bus: %s" % [next_player_idx, next_player.bus])
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
##
## [param fade_duration] The duration of the fade out in seconds.
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
##
## [param stream] The AudioStream of the sound effect to play.
## [param pitch_variance] The range of random pitch scale variation (+/- variance).
## [param bus] The name of the audio bus to route the sound to.
## Returns the instantiated AudioStreamPlayer.
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
##
## [param stream] The AudioStream of the sound effect to play.
## [param global_pos] The global Vector2 position in 2D space where the sound should play.
## [param pitch_variance] The range of random pitch scale variation (+/- variance).
## [param bus] The name of the audio bus to route the sound to.
## Returns the instantiated AudioStreamPlayer2D.
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
##
## [param node] The root Node from which to recursively hook child button signals.
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

## Sets the volume level for a specific audio bus.
##
## [param bus_name] The name of the audio bus to adjust.
## [param linear_volume] The volume level, represented as a linear value from 0.0 (silent) to 1.0 (full).
func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var clamped = clampf(linear_volume, 0.0, 1.0)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamped))
	else:
		push_warning("Audio bus not found: " + bus_name)


## Gets the current linear volume level of a specific audio bus.
##
## [param bus_name] The name of the audio bus.
## Returns the linear volume level from 0.0 to 1.0.
func get_bus_volume(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	push_warning("Audio bus not found: " + bus_name)
	return 0.0


## Mutes or unmutes a specific audio bus.
##
## [param bus_name] The name of the audio bus.
## [param is_muted] True to mute the bus, false to unmute it.
func set_bus_mute(bus_name: String, is_muted: bool) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, is_muted)
	else:
		push_warning("Audio bus not found: " + bus_name)


## Checks if a specific audio bus is currently muted.
##
## [param bus_name] The name of the audio bus.
## Returns true if the bus is muted, false otherwise.
func is_bus_muted(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.is_bus_mute(bus_idx)
	push_warning("Audio bus not found: " + bus_name)
	return false
