extends Node

signal session_started(topic: String)
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
	"Math": {
		"Logarithms": [
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
}
var mock_questions_pool: Array = []

var current_session_id: int = 0
var current_question_index: int = 0
var current_question_data: Dictionary = {}
var remaining_attempts: int = 2
var total_questions: int = 3

enum TestType {
	Math,
	UkrLang,
	UkrHstr
}


func _unhandled_key_input(event: InputEvent) -> void:
	if test_ui and is_instance_valid(test_ui) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_test()


func start_test(test_type: TestType, test_topic: String) -> void:
	get_tree().paused = true
	if test_type == TestType.Math:
		_init_math_ui(test_topic)

func _init_math_ui(test_topic: String) -> void:
	var math_ui: MathUI = math_ui_scene.instantiate()
	get_tree().current_scene.add_child(math_ui)
	math_ui.test_topic_label.text = test_topic
	test_ui = math_ui


func end_test() -> void:
	if test_ui and is_instance_valid(test_ui):
		test_ui.queue_free()
		test_ui = null
	get_tree().paused = false
