## A finite state machine that manages and coordinates different player states.
##
## It registers all child [PlayerState] nodes, sets their references to the player (owner)
## and this state machine, and handles transitioning between states, routing inputs,
## processing, and physics updates to the currently active state.
class_name PlayerStateMachine
extends Node

## The initial state the player starts in when the state machine runs.
@export var initial_state: PlayerState

## The currently active player state.
var current_state: PlayerState

## A dictionary storing all registered states, mapping their lowercase names to the state nodes.
var states: Dictionary = {}

## Dictionary mapping Vector2 directions to their string representation.
const DIR_NAMES: Dictionary = {
	Vector2.UP: "up",
	Vector2.DOWN: "down",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right"
}

## The player's current facing direction.
var direction: Vector2 = Vector2.DOWN

## Returns the string representation of the current [member direction].
## Defaults to "down" if the direction is not found in [constant DIR_NAMES].
func get_direction_name() -> String:
	return DIR_NAMES.get(direction, "down")

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
	var player = owner as Player
	if player and player.is_dead:
		return
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	var player = owner as Player
	if player and player.is_dead:
		player.velocity = Vector2.ZERO
		return
	if current_state:
		current_state.physics_update(delta)

## Transitions the state machine from the current state to the state matching [param new_state_name].
## Does nothing if the requested state does not exist in the [member states] dictionary.
func transition_to(new_state_name: String) -> void:
	var target_state: PlayerState = states.get(new_state_name.to_lower())
	if not target_state:
		return
	if current_state:
		current_state.exit()
	current_state = target_state
	current_state.enter()
