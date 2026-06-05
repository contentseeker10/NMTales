extends TestUI

var _drag_button_scene: PackedScene = preload("res://ui/components/drag_and_drop/drag_button.tscn")

#region Node imports

@onready var left_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/LeftElementsBox
@onready var right_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/RightElementsBox
@onready var content_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/BaseContainer/PanelContainer/MarginContainer/ContentFlowContainer
@onready var test_topic_label: Label = $CenterContainer/TestContainer/TopicLabel

#endregion


func _ready() -> void:
	TestManager.session_started.connect(_on_session_started)
	TestManager.question_loaded.connect(_on_question_loaded)
	TestManager.answer_checked.connect(_on_answer_checked)
	TestManager.session_finished.connect(_on_session_finished)


func _on_session_started() -> void:
	pass


#region Loading Question

func _on_question_loaded(question_data: Dictionary, _current_index: int) -> void:
	_load_answers(question_data.get("answers", []))

func _load_answers(answers: Array) -> void:
	if answers.is_empty():
		push_error("Could not load answers")
		return
	_fill_elements_box(answers, 0, left_container)
	# TODO: _fill_elements_box(answers, 6, right_container)
	# Add filling of right box once API adjusted. API must always have exactly 12 answers.

func _fill_elements_box(answers: Array, answer_index: int, container: HFlowContainer) -> void:
	var areas: Array[DropArea] = []
	areas.assign(container.get_children())
	var size: int = min(answers.size(), areas.size())
	for i in range(size):
		var element: DragButton = _drag_button_scene.instantiate()
		element.text = answers[i + answer_index].get("text", "error")
		element.id = answers[i + answer_index].get("id", -1)
		areas[i].active_container.add_child(element)

#endregion


func _on_answer_checked(is_correct: bool, _is_completed: bool, _is_failed: bool, remaining_attempts: int) -> void:
	pass


func _on_session_finished(_success: bool) -> void:
	TestManager.end_test()
