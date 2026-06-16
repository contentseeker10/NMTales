## Abstract base class for all player state implementations within the player state machine.
## Defines the standard interface for state lifecycle methods and execution callbacks.
@abstract class_name PlayerState
extends Node

## Reference to the main [Player] character instance that this state controls.
var player: Player
## Reference to the parent [PlayerStateMachine] coordinating state transitions.
var state_machine: PlayerStateMachine

## Called when the state is entered. Initialize state parameters and play relevant animations.
@abstract func enter() -> void

## Called when transitioning away from this state. Clean up state-specific data or effects.
@abstract func exit() -> void

## Handles input events directed to this player state.
@abstract func handle_input(event: InputEvent) -> void

## Called during the frame processing step (equivalent to _process). Use for non-physics logic.
@abstract func update(delta: float) -> void

## Called during the physics processing step (equivalent to _physics_process). Use for movement and physics calculations.
@abstract func physics_update(delta: float) -> void
