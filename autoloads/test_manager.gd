extends Node

signal session_started()
signal question_loaded(question_data: Dictionary, current_index: int)
signal answer_checked(is_correct: bool, remaining_attempts: int, is_completed: bool)
signal session_finished(success: bool)

var test_ui: TestUI

var math_ui_scene: PackedScene = preload("res://ui/menus/test/math/math_ui.tscn")
var lang_ui_scene: PackedScene
var hstr_ui_scene: PackedScene

# Set to false, when backend is ready
@export var mock_mode: bool = true
const MOCK_QUESTIONS: Dictionary = {
		"questions": [
			{
				"id": 101,
				"text": "Знайдіть корінь рівняння log_2(x) = 3:",
				"imagePath": "res://locations/test/assets/logo.png",
				"answers": [
					{"id": 1001, "text": "x = 5"},
					{"id": 1002, "text": "x = 6"},
					{"id": 1003, "text": "x = 8"},
					{"id": 1004, "text": "x = 9"}
				],
				"correct_id": 1003
			},
			{
				"id": 102,
				"text": "Обчисліть значення виразу log_3(9):",
				"imagePath": "res://locations/test/assets/logo.png",
				"answers": [
					{"id": 2001, "text": "1"},
					{"id": 2002, "text": "2"},
					{"id": 2003, "text": "3"},
					{"id": 2004, "text": "4"}
				],
				"correct_id": 2002
			},
			{
				"id": 103,
				"text": "Обчисліть значення виразу x + 2 = 4:",
				"imagePath": "res://locations/test/assets/logo.png",
				"answers": [
					{"id": 3001, "text": "2"},
					{"id": 3002, "text": "-2"},
					{"id": 3003, "text": "0"},
					{"id": 3004, "text": "1"}
				],
				"correct_id": 3001
			}
		]
}
var mock_questions_pool: Array = []

var current_session_id: int = 0
var current_question_index: int = 0
var current_question_data: Dictionary = {}

const ATTEMPTS: int = 2
const TOTAL_QUESTIONS: int = 3


func start_test(test_type: String, test_topic: String) -> void:
	get_tree().paused = true
	_init_test_ui(test_type, test_topic)
	_request_test_session()

func _init_test_ui(test_type: String, test_topic: String) -> void:
	var ui: TestUI
	ui = math_ui_scene.instantiate() if test_type == "math" else lang_ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.test_topic_label.text = test_topic
	test_ui = ui

func _request_test_session() -> void:
	if mock_mode:
		_load_mock_session()
	
	# HTTP Request to Backend...
	
	session_started.emit()
	question_loaded.emit(current_question_data, current_question_index)

func _load_mock_session() -> void:
	mock_questions_pool = MOCK_QUESTIONS.get("questions")
	current_question_data = mock_questions_pool[current_question_index]


func submit_answer(answer_id: int) -> void:
	pass


func _unhandled_key_input(event: InputEvent) -> void:
	if test_ui and is_instance_valid(test_ui) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_test()


func end_test() -> void:
	if test_ui and is_instance_valid(test_ui):
		test_ui.queue_free()
		test_ui = null
	get_tree().paused = false
