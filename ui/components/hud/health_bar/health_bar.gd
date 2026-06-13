class_name HealthBar
extends MarginContainer

@onready var icons_list: HBoxContainer = $IconsList


func _ready() -> void:
	for icon in icons_list.get_children():
		if icon is TextureRect:
			icon.texture = icon.texture.duplicate()


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
