## A spawner that instantiates a specified number of enemies within its area shape boundaries.
## It can trigger spawns when a player enters the area or at the end of a session if the player is inside.
class_name EnemySpawner
extends Area2D

var _rng := RandomNumberGenerator.new()

var _enemy_scene: PackedScene = preload("res://parts/enemy/enemy.tscn")

@onready var coll_shape: CollisionShape2D = $CollisionShape2D
var shape: Shape2D

## The number of enemies to spawn.
@export var amount: int = 10
## If true, the spawner detects player entry to trigger spawning and queues itself free afterward.
@export var player_detecting: bool = true


func _ready() -> void:
	TestManager.session_finished.connect(_on_session_finished)
	shape = coll_shape.shape


## Spawns the configured amount of enemies randomly distributed within the boundaries of the spawner's shape.
## If player_detecting is true, the spawner queues itself free after spawning.
func spawn() -> void:
	for i in range(amount):
		var x := _rng.randf_range(-shape.size.x / 2, shape.size.x / 2)
		var y := _rng.randf_range(-shape.size.y / 2, shape.size.y / 2)
		var pos := Vector2(x, y)
		_init_enemy(pos)
	if player_detecting:
		queue_free()

## Initializes and adds an enemy instance to the parent node at the specified local offset position.
func _init_enemy(pos: Vector2) -> void:
	var enemy: Enemy = _enemy_scene.instantiate()
	enemy.skin = _get_random_skin()
	get_parent().add_child(enemy)
	enemy.global_position = global_position + pos

## Selects a random enemy skin type.
func _get_random_skin() -> Enemy.EnemySkin:
	var skin: Enemy.EnemySkin
	var num := _rng.randi_range(0, 2)
	match num:
		0:
			skin = Enemy.EnemySkin.VampireGreen
		1:
			skin = Enemy.EnemySkin.VampireBlue
		2:
			skin = Enemy.EnemySkin.VampireRed
	return skin


## Triggered when a body enters the spawner's detection area. Spawns enemies if the body is the Player.
func _on_body_entered(body: Node2D) -> void:
	if player_detecting:
		if body and body is Player:
			spawn()


## Triggered when a test session finishes. If the session failed and the player is within the spawner's boundaries, spawns the enemies.
func _on_session_finished(success: bool) -> void:
	if not success:
		var player = get_tree().get_first_node_in_group("player") as Player
		if is_instance_valid(player):
			var collision_shape = $CollisionShape2D.shape as RectangleShape2D
			if collision_shape:
				var local_player_pos = to_local(player.global_position)
				var half_size = collision_shape.size / 2.0
				if abs(local_player_pos.x) <= half_size.x and abs(local_player_pos.y) <= half_size.y:
					spawn()

