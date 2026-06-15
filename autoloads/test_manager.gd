extends Node

#region Maintenance variables

var _test_ui: TestUI

var _math_ui_scene: PackedScene = preload("res://ui/menus/test/math/math_ui.tscn")
var _lang_ui_scene: PackedScene = preload("res://ui/menus/test/lang/lang_ui.tscn")
@warning_ignore("unused_private_class_variable") var _hstr_ui_scene: PackedScene

var _word_regex := RegEx.new()

#endregion

#region Backend specific variables

var current_session_id: int = 0
var current_question_index: int = 0
var current_question_data: Dictionary = {}
var current_topic: String = ""

#endregion

#region Signals

signal session_started()
signal question_loaded(question_data: Dictionary, current_index: int)
signal answer_checked(is_correct: bool, is_completed: bool, is_failed: bool, 
					remaining_attempts: int, slot_results: Array)
signal session_finished(success: bool)

#endregion

var is_test_active := false


func _ready() -> void:
	_word_regex.compile("(\\[\\d+\\])|(\\S+)")
	process_mode = Node.PROCESS_MODE_ALWAYS


#region Starting Test-session

func start_test(test_type: String, test_topic: String) -> void:
	if is_test_active:
		return
	is_test_active = true
	current_topic = test_topic
	_set_player_active(false)
	_init_test_ui(test_type, test_topic)
	await _request_test_session(test_type, test_topic)
	#get_tree().paused = true

func _init_test_ui(test_type: String, test_topic: String) -> void:
	var ui: TestUI
	ui = _math_ui_scene.instantiate() if test_type == "Math" else _lang_ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.test_topic_label.text = test_topic
	_test_ui = ui

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
		push_error("Error requesting for Test session. Status: " + str(response[1]) \
				+ " " + response[3].get_string_from_utf8())
		return
	
	session_started.emit()
	question_loaded.emit(current_question_data, current_question_index)


func parse_text(text: String) -> Array:
	var parsed: Array
	var matches := _word_regex.search_all(text)
	for m in matches:
		var placeholder := m.get_string(1).remove_chars("[]")
		var normal_word := m.get_string(2)
		if placeholder != "":
			parsed.append(int(placeholder))
		elif normal_word != "":
			parsed.append(normal_word)
	return parsed

#endregion


#region Submitting answers to Questions

func submit_answer(answer_id: int, slots: Array[Dictionary] = []) -> void:
	var req_body: Dictionary = { "sessionId": current_session_id, "answerId": answer_id, "slots": slots }
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
		var slot_results: Array = body.get("slotResults", [])
		
		answer_checked.emit(is_correct, is_completed, is_failed, remaining_attempts, slot_results)
		
		if is_completed or is_failed:
			session_finished.emit(not is_failed)
			if is_completed and not is_failed:
				EventBus.quiz_completed.emit(current_topic)
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

func end_test() -> void:
	if _test_ui and is_instance_valid(_test_ui):
		_test_ui.queue_free()
		_test_ui = null
	is_test_active = false
	_set_player_active(true)

#endregion


func _set_player_active(active: bool) -> void:
	var player: Player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		if active:
			player.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			player.process_mode = Node.PROCESS_MODE_DISABLED
