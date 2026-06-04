extends TestUI

#region Node imports

@onready var left_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/LeftElementsBox
@onready var right_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/RightElementsBox

#endregion


func _ready() -> void:
	_connect_buttons()
	

func _connect_buttons() -> void:
	for drop_area in left_container.get_children():
		if drop_area.drag_button:
			drop_area.drag_button.pressed.connect(func(): pass)
	for drop_area in right_container.get_children():
		if drop_area.drag_button:
			drop_area.drag_button.pressed.connect(func(): pass)


func _process(_delta: float) -> void:
	pass
