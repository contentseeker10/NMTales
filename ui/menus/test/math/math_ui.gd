class_name MathUI
extends TestUI

#region Node imports

@onready var test_topic_label: Label = $CenterContainer/TestContainer/HeaderVBox/TopicNameLabel
@onready var progress_label: Label = $CenterContainer/TestContainer/HeaderVBox/ProgressLabel
@onready var attempts_label: Label = $CenterContainer/TestContainer/HeaderVBox/AttemptsLabel
@onready var question_label: Label = $CenterContainer/TestContainer/TaskPanel/MarginContainer/CenterContainer/VBoxContainer/QuestionLabel
@onready var question_image: TextureRect = $CenterContainer/TestContainer/TaskPanel/MarginContainer/CenterContainer/VBoxContainer/QuestionImage
@onready var answers_grid: GridContainer = $CenterContainer/TestContainer/AnswersGrid

#endregion


func _ready() -> void:
	TestManager.session_started.connect(_on_session_started)
	TestManager.question_loaded.connect(_on_question_loaded)
	TestManager.answer_checked.connect(_on_answer_checked)
	TestManager.session_finished.connect(_on_session_finished)


func _on_session_started() -> void:
	pass


#region Loading Question

func _on_question_loaded(question_data: Dictionary, current_index: int) -> void:
	_update_progress(current_index)
	_update_question(question_data)
	_update_answers(question_data)

func _update_progress(index: int) -> void:
	progress_label.text = "Задача " + str(index + 1) + "/3"

func _update_question(question_data: Dictionary) -> void:
	question_label.text = question_data.get("text", "error")
	var image_path: String = question_data.get("imagePath", "res://assets/shared/logo.png")
	await _load_question_image(image_path)

func _load_question_image(image_path: String) -> void:
	var local_path: String = "user://assets/downloaded" + image_path
	if FileAccess.file_exists(local_path):
		_convert_image_to_texture(local_path)
	else:
		if await NetworkManager.download_image(image_path):
			_convert_image_to_texture(local_path)
		else:
			question_image.texture = load("res://assets/shared/logo.png")

func _convert_image_to_texture(path: String) -> void:
	var image: Image = Image.load_from_file(path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		question_image.texture = texture
	else:
		push_error("Unable to load image " + path)

func _update_answers(question_data: Dictionary) -> void:
	var answers_pool: Array = question_data.get("answers", [])
	if answers_pool.is_empty():
		push_error("Answers pool is empty for question: " + question_data.get("text", "error"))
		return
	var answer_buttons: Array = answers_grid.get_children()
	for i in range(answers_pool.size()):
		_clean_answer_button(answer_buttons[i])
		_connect_answer_button(answers_pool[i], answer_buttons[i])

func _clean_answer_button(answer_button: Button) -> void:
	for connection in answer_button.pressed.get_connections():
		answer_button.pressed.disconnect(connection.callable)

func _connect_answer_button(answer_data: Dictionary, answer_button: Button) -> void:
	var answer_id: int = answer_data.get("id", -1)
	answer_button.pressed.connect(func(): TestManager.submit_answer(answer_id), CONNECT_ONE_SHOT)
	answer_button.text = answer_data.get("text", "error")
	answer_button.show()

#endregion


func _on_answer_checked(is_correct: bool, _is_completed: bool, _is_failed: bool, remaining_attempts: int) -> void:
	if not is_correct:
		attempts_label.text = "Неправильно. Залишилось спроб: " + str(remaining_attempts)
		attempts_label.show()
	else:
		attempts_label.hide()


func _on_session_finished(_success: bool) -> void:
	TestManager.end_test()
