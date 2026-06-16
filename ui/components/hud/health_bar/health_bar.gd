## A UI component representing the player's health bar.
##
## Displays a list of heart icons to visualize current health,
## supporting full, half, and empty heart states.
class_name HealthBar
extends MarginContainer

## Container holding individual heart icon nodes.
@onready var icons_list: HBoxContainer = $IconsList


## Initializes the health bar by duplicating heart textures to prevent shared states.
func _ready() -> void:
	for icon in icons_list.get_children():
		if icon is TextureRect:
			icon.texture = icon.texture.duplicate()


## Updates the displayed health bar based on the player's current health points (HP).
##
## Compares the health value against predefined thresholds (10 HP per heart, 5 HP for half heart)
## and updates each heart icon accordingly.
func update_health(hp: int) -> void:
	var icons := icons_list.get_children()
	for i in range(icons.size()):
		var icon := icons[icons.size() - 1 - i] as HeartIcon
		if hp >= (i + 1) * 10:
			icon.set_full()
		elif hp >= i * 10 + 5:
			icon.set_half()
		else:
			icon.set_empty()

