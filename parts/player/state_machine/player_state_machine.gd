class_name PlayerStateMachine
extends Node

@export var initial_state: PlayerState

var current_state: PlayerState
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready
	
	for child in get_children():
		if child is PlayerState:
			states[child.name.to_lower()] = child
			child.player = owner as Player
			child.state_machine = self
	
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(new_state_name: String) -> void:
	var targer_state: PlayerState = states.get(new_state_name.to_lower())
	if not targer_state:
		return
	if current_state:
		current_state.exit()
	current_state = targer_state
	current_state.enter()
