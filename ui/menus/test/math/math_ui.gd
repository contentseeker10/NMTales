## UI controller for math tests.
##
## Manages the display of question text, downloading and showing images from the server,
## rendering answer choices, and feeding user interaction back to the TestManager.
class_name MathUI
extends TestUI

#region Node imports

## Label displaying the name of the test topic.
@onready var test_topic_label: Label = $CenterContainer/TestContainer/HeaderVBox/TopicNameLabel
## Label indicating the current task progress (e.g., "Question 1/3").
@onready var progress_label: Label = $CenterContainer/TestContainer/HeaderVBox/ProgressLabel
## Label displaying the remaining attempts for the current question.
@onready var attempts_label: Label = $CenterContainer/TestContainer/HeaderVBox/AttemptsLabel
## Label displaying the text of the current question.
@onready var question_label: Label = $CenterContainer/TestContainer/TaskPanel/MarginContainer/CenterContainer/VBoxContainer/QuestionLabel
## TextureRect displaying an image associated with the question.
@onready var question_image: TextureRect = $CenterContainer/TestContainer/TaskPanel/MarginContainer/CenterContainer/VBoxContainer/QuestionImage
## GridContainer containing the answer choice buttons.
@onready var answers_grid: GridContainer = $CenterContainer/TestContainer/AnswersGrid

#endregion


## Connects UI handlers to signals from the TestManager.
func _ready() -> void:
	TestManager.session_started.connect(_on_session_started)
	TestManager.question_loaded.connect(_on_question_loaded)
	TestManager.answer_checked.connect(_on_answer_checked)
	TestManager.session_finished.connect(_on_session_finished)


## Callback triggered when a test session starts.
func _on_session_started() -> void:
	pass


#region Loading Question

## Updates the UI with the loaded question details and current question index.
func _on_question_loaded(question_data: Dictionary, current_index: int) -> void:
	_update_progress(current_index)
	_update_question(question_data)
	_update_answers(question_data)


## Updates the progress label based on the current question index.
func _update_progress(index: int) -> void:
	progress_label.text = "Задача " + str(index + 1) + "/3"


## Updates the question text and starts loading its associated image.
func _update_question(question_data: Dictionary) -> void:
	question_label.text = question_data.get("text", "error")
	var image_path: String = question_data.get("imagePath", "res://assets/shared/logo.png")
	await _load_question_image(image_path)


## Loads the question image from the local filesystem or downloads it if not present.
func _load_question_image(image_path: String) -> void:
	var local_path: String = "user://assets/downloaded" + image_path
	if FileAccess.file_exists(local_path):
		_convert_image_to_texture(local_path)
	else:
		if await NetworkManager.download_image(image_path):
			_convert_image_to_texture(local_path)
		else:
			question_image.texture = load("res://assets/shared/logo.png")


## Converts a local image file into a texture and displays it in the question image node.
func _convert_image_to_texture(path: String) -> void:
	var image: Image = Image.load_from_file(path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		question_image.texture = texture
	else:
		push_error("Unable to load image " + path)


## Sets up answer buttons with choices provided by the question data.
func _update_answers(question_data: Dictionary) -> void:
	var answers_pool: Array = question_data.get("answers", [])
	if answers_pool.is_empty():
		push_error("Answers pool is empty for question: " + question_data.get("text", "error"))
		return
	var answer_buttons: Array = answers_grid.get_children()
	for i in range(answers_pool.size()):
		_clean_answer_button(answer_buttons[i])
		_connect_answer_button(answers_pool[i], answer_buttons[i])


## Disconnects existing press signals from an answer button to prepare it for recycling.
func _clean_answer_button(answer_button: Button) -> void:
	for connection in answer_button.pressed.get_connections():
		answer_button.pressed.disconnect(connection.callable)


## Configures an answer button with the text and sets its action to submit the answer ID.
func _connect_answer_button(answer_data: Dictionary, answer_button: Button) -> void:
	var answer_id: int = answer_data.get("id", -1)
	answer_button.pressed.connect(func(): TestManager.submit_answer(answer_id), CONNECT_ONE_SHOT)
	answer_button.text = answer_data.get("text", "error")
	answer_button.show()

#endregion


## Callback triggered when an answer is checked; shows remaining attempts if incorrect.
func _on_answer_checked(is_correct: bool, _is_completed: bool, _is_failed: bool, 
					remaining_attempts: int, _slot_results: Array[Dictionary]) -> void:
	if not is_correct:
		attempts_label.text = "Неправильно. Залишилось спроб: " + str(remaining_attempts)
		attempts_label.show()
	else:
		attempts_label.hide()


## Callback triggered when the session finishes, completing the test via TestManager.
func _on_session_finished(_success: bool) -> void:
	TestManager.end_test()
