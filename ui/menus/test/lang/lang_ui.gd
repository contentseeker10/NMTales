## A UI class that handles language-based test/quiz interfaces.
##
## This UI allows users to fill in the blanks in a text passage by dragging and
## dropping answer elements into designated drop areas within the text content.
extends TestUI

#region Maintenance variables

## Preloaded scene for the draggable answer button.
var _drag_button_scene: PackedScene = preload("res://ui/components/drag_and_drop/drag_button.tscn")
## Preloaded scene for the drop areas within the text passage.
var _drop_area_scene: PackedScene = preload("res://ui/components/drag_and_drop/drop_area.tscn")

## List of drop areas that the user currently has selected or filled.
var _selected_elements: Array[DropArea]

#endregion

#region Node imports

## The left container that holds a subset of draggable answer choices.
@onready var left_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/LeftElementsBox
## The right container that holds a subset of draggable answer choices.
@onready var right_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/RightElementsBox
## The central container displaying the text passage with blank drop areas.
@onready var content_container: HFlowContainer = $CenterContainer/TestContainer/ElementsContainer/BaseContainer/PanelContainer/MarginContainer/ContentFlowContainer
## The label displaying the topic of the current test.
@onready var test_topic_label: Label = $CenterContainer/TestContainer/TopicLabel
## Timer used to delay screen transitions after a test session finishes.
@onready var timer: Timer = $Timer

#endregion

## Connects to relevant [TestManager] signals to drive the test lifecycle.
func _ready() -> void:
	TestManager.session_started.connect(_on_session_started)
	TestManager.question_loaded.connect(_on_question_loaded)
	TestManager.answer_checked.connect(_on_answer_checked)
	TestManager.session_finished.connect(_on_session_finished)


## Called when the test session starts.
func _on_session_started() -> void:
	pass


#region Loading Question

## Called when a new question is loaded.
##
## [param question_data] contains the question text and answer choices.
## [param _current_index] is the current index of the question in the session.
func _on_question_loaded(question_data: Dictionary, _current_index: int) -> void:
	_clear_content()
	_load_answers(question_data.get("answers", []))
	_load_text(question_data.get("text", "error"))

## Clears the text content, left/right answer choices, and active drop areas.
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
	
	_selected_elements.clear()

## Instantiates and distributes the provided list of answers.
##
## Splits the [param answers] array to populate both the left and right option containers.
func _load_answers(answers: Array) -> void:
	if answers.is_empty():
		push_error("Could not load answers")
		return
	_fill_elements_box(answers, 0, left_container)
	_fill_elements_box(answers, 6, right_container)

## Instantiates draggable buttons for answers and places them inside designated drop areas.
##
## [param answers] is the complete list of answers.
## [param answer_index] is the starting index in the answers list to pull from.
## [param container] is the container (left or right) to fill.
func _fill_elements_box(answers: Array, answer_index: int, container: HFlowContainer) -> void:
	var areas: Array[DropArea] = []
	areas.assign(container.get_children())
	var size: int = min(answers.size() - answer_index, areas.size())
	for i in range(size):
		var element: DragButton = _drag_button_scene.instantiate()
		element.text = answers[i + answer_index].get("text", "error")
		element.id = answers[i + answer_index].get("id", -1)
		areas[i].active_container.add_child(element)

## Parses and instantiates the text passage into words and drop areas.
##
## [param text] is the raw text string containing slot indicators to be parsed.
func _load_text(text: String) -> void:
	var tokens := TestManager.parse_text(text)
	for token in tokens:
		if token is String:
			_add_word(token)
		elif token is int:
			_add_drop_area(token)

## Helper to add a word label to the text flow.
##
## [param word] is the word to be displayed.
func _add_word(word: String) -> void:
	var word_label := Label.new()
	word_label.add_theme_font_size_override("font_size", 10)
	word_label.add_theme_color_override("font_color", "#2A201C")
	word_label.text = word
	content_container.add_child(word_label)

## Helper to add an interactive drop area to the text flow.
##
## [param index] is the slot index for this drop area.
func _add_drop_area(index: int) -> void:
	var drop_area: DropArea = _drop_area_scene.instantiate()
	drop_area.index = index
	content_container.add_child(drop_area)

#endregion


#region Submitting Answer

## Callback triggered when the submit/use button is pressed.
func _on_use_button_pressed() -> void:
	var user_input := _collect_user_input()
	TestManager.submit_answer(0, user_input)

## Gathers the current user placement of answers in the text passage.
##
## Returns an array of dictionaries containing slot index and answer ID pairs.
func _collect_user_input() -> Array[Dictionary]:
	var input: Array[Dictionary]
	if not content_container.get_children().is_empty():
		for child in content_container.get_children():
			if child is DropArea and child.drag_button:
				var entry: Dictionary = { 
					"slotIndex": child.index, 
					"answerId": child.drag_button.id 
				}
				input.append(entry)
				_selected_elements.append(child)
	return input

## Callback triggered when the answer has been checked by [TestManager].
##
## Receives status flags and the correctness results per slot.
func _on_answer_checked(_is_correct: bool, _is_completed: bool, _is_failed: bool, 
					_remaining_attempts: int, slot_results: Array) -> void:
	_show_results(slot_results)

## Marks each selected drop area as correct or incorrect based on results.
##
## [param results] is an array of dictionaries indicating slot correctness.
func _show_results(results: Array) -> void:
	for i in range(results.size()):
		var is_correct: bool = results[i].get("isCorrect", false)
		_selected_elements[i].mark_correct(is_correct)

#endregion


## Callback triggered when the entire test session is finished.
##
## [param _success] indicates whether the session was passed successfully.
func _on_session_finished(_success: bool) -> void:
	timer.start()
	await timer.timeout
	TestManager.end_test()
