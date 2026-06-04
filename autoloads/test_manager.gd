extends Node

#region Signals

signal session_started()
signal question_loaded(question_data: Dictionary, current_index: int)
signal answer_checked(is_correct: bool, is_completed: bool, is_failed: bool, remaining_attempts: int)
signal session_finished(success: bool)

#endregion

#region Maintenance variables

var test_ui: TestUI

var math_ui_scene: PackedScene = preload("res://ui/menus/test/math/math_ui.tscn")
var lang_ui_scene: PackedScene
var hstr_ui_scene: PackedScene

#endregion

#region Backend specific variables

var current_session_id: int = 0
var current_question_index: int = 0
var current_question_data: Dictionary = {}

#endregion


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


#region Starting Test-session

func start_test(test_type: String, test_topic: String) -> void:
	_init_test_ui(test_type, test_topic)
	await _request_test_session(test_type, test_topic)
	get_tree().paused = true

func _init_test_ui(test_type: String, test_topic: String) -> void:
	var ui: TestUI
	ui = math_ui_scene.instantiate() if test_type == "Math" else lang_ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.test_topic_label.text = test_topic
	test_ui = ui

func _request_test_session(test_type: String, test_topic: String) -> void:
	var req_body: Dictionary = { "subject": test_type, "topic": test_topic }
	var request: HTTPRequest = NetworkManager.send_post("/api/Test/start", req_body, AuthManager.token_header)
	if not request:
		push_error("Error creating request for Test.")
		return
	
	var response: Array = await request.request_completed
	request.queue_free()
	
	if response[1] == 200:
		var body: Dictionary = JSON.parse_string(response[3].get_string_from_utf8())
		current_session_id = body.get("sessionId", -1)
		current_question_index = body.get("currentQuestionIndex", -1)
		current_question_data = body.get("question", {})
	else:
		push_error("Error requesting for Test session. Status: " + str(response[1]))
		return
	
	session_started.emit()
	question_loaded.emit(current_question_data, current_question_index)

#endregion


#region Submitting answers to Questions

func submit_answer(answer_id: int) -> void:
	var req_body: Dictionary = { "sessionId": current_session_id, "answerId": answer_id, "slots": [] }
	var request: HTTPRequest = NetworkManager.send_post("/api/Test/submit", req_body, AuthManager.token_header)
	if not request:
		push_error("Error creating a submition to Test.")
		return
	
	var response: Array = await request.request_completed
	request.queue_free()
	
	if response[1] == 200:
		var body: Dictionary = JSON.parse_string(response[3].get_string_from_utf8())
		
		var is_correct: bool = body.get("correct")
		var is_completed: bool = body.get("completed")
		var is_failed: bool = body.get("failed", false)
		var remaining_attempts: int = body.get("remainingAttempts", 2)
		
		answer_checked.emit(is_correct, is_completed, is_failed, remaining_attempts)
		
		if is_completed or is_failed:
			session_finished.emit(not is_failed)
		else:
			if is_correct:
				_load_next_question(body.get("nextQuestion", {}))
				question_loaded.emit(current_question_data, current_question_index)
	else:
		push_error("Error submitting answer for Test. Status: ", str(response[1]), \
				" ", response[3].get_string_from_utf8())
		return

func _load_next_question(question_data: Dictionary) -> void:
	current_question_data = question_data
	current_question_index += 1

#endregion


#region Closing Test

func _unhandled_key_input(event: InputEvent) -> void:
	if test_ui and is_instance_valid(test_ui) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_test()

func end_test() -> void:
	if test_ui and is_instance_valid(test_ui):
		test_ui.queue_free()
		test_ui = null
	get_tree().paused = false

#endregion
