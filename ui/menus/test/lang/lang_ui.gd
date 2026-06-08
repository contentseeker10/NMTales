extends TestUI

#region Maintenance variables

var _drag_button_scene: PackedScene = preload("res://ui/components/drag_and_drop/drag_button.tscn")
var _drop_area_scene: PackedScene = preload("res://ui/components/drag_and_drop/drop_area.tscn")

#endregion

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
	_clear_content()
	_load_answers(question_data.get("answers", []))
	_load_text(question_data.get("text", "error"))

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

func _load_text(text: String) -> void:
	var tokens := TestManager.parse_text(text)
	for token in tokens:
		if token is String:
			_add_word(token)
		elif token is int:
			_add_drop_area(token)

func _add_word(word: String) -> void:
	var word_label := Label.new()
	word_label.add_theme_font_size_override("font_size", 10)
	word_label.add_theme_color_override("font_color", "#2A201C")
	word_label.text = word
	content_container.add_child(word_label)

func _add_drop_area(index: int) -> void:
	var drop_area: DropArea = _drop_area_scene.instantiate()
	drop_area.index = index
	content_container.add_child(drop_area)

#endregion


func _on_answer_checked(is_correct: bool, _is_completed: bool, _is_failed: bool, remaining_attempts: int) -> void:
	pass


func _on_use_button_pressed() -> void:
	pass


func _on_session_finished(_success: bool) -> void:
	TestManager.end_test()


func _clear_content() -> void:
	if not content_container.get_children().is_empty():
		for child in content_container.get_children():
			child.queue_free()
	
	for child in left_container.get_children() as Array[DropArea]:
		if not child.active_container.get_children().is_empty():
			var elem := child.active_container.get_child(0)
			if elem and is_instance_valid(elem):
				elem.queue_free()
	
	for child in right_container.get_children() as Array[DropArea]:
		if not child.active_container.get_children().is_empty():
			var elem := child.active_container.get_child(0)
			if elem and is_instance_valid(elem):
				elem.queue_free()
