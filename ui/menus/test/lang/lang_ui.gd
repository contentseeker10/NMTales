extends TestUI

#region Node imports

@onready var left_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/LeftElementsBox
@onready var right_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/RightElementsBox
@onready var content_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/BaseContainer/PanelContainer/MarginContainer/ContentFlowContainer
@onready var test_topic_label: Label = $CenterContainer/TestContainer/TopicLabel

#endregion


func _ready() -> void:
	_connect_buttons()

func _connect_buttons() -> void:
	pass


func _process(_delta: float) -> void:
	pass
