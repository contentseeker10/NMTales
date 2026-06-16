## A 2D marker representing a player or entity spawn point in the game world.
##
## This marker defines a specific location and direction (via transform) where
## entities (such as the player) can be instantiated or repositioned.
class_name SpawnPoint
extends Marker2D

## Unique identifier for this spawn point.
## Used to look up the correct location when loading a scene or transitioning between areas.
@export var spawn_point_id: String

