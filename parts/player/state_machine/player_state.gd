@abstract class_name PlayerState
extends Node

var player: Player
var state_machine: PlayerStateMachine

@abstract func enter() -> void

@abstract func exit() -> void

@abstract func handle_input(event: InputEvent) -> void

@abstract func update(delta: float) -> void

@abstract func physics_update(delta: float) -> void
