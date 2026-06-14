class_name PageContainer
extends MarginContainer

var _name_change_id: int = 0
var _text_change_id: int = 0

#region Node imports

@onready var name_edit: LineEdit = $VBoxContainer/HFlowContainer/NameEdit
@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var formatted_text: RichTextLabel = $VBoxContainer/FormattedText

@onready var name_edit_timer: Timer = $VBoxContainer/HFlowContainer/NameEdit/Timer
@onready var text_edit_timer: Timer = $VBoxContainer/TextEdit/Timer

@onready var delete_button: Button = $VBoxContainer/HFlowContainer/DeleteButton

#endregion

#region Backend specific vars

var page_id: int
var page_name: String
var page_text: String

#endregion

var index: int


func _ready() -> void:
	name_edit.text = page_name
	text_edit.text = page_text
	formatted_text.text = page_text


#region Updating data to backend

func _on_name_edit_text_changed(new_text: String) -> void:
	page_name = new_text
	_name_change_id += 1
	var current_id = _name_change_id
	name_edit_timer.start()
	await name_edit_timer.timeout
	if current_id != _name_change_id:
		return
	NotebookManager.update_page(page_id, page_name, page_text)
	EventBus.page_title_changed.emit(index, new_text)


func _on_text_edit_text_changed() -> void:
	page_text = text_edit.text
	formatted_text.text = text_edit.text
	_text_change_id += 1
	var current_id = _text_change_id
	text_edit_timer.start()
	await text_edit_timer.timeout
	if current_id != _text_change_id:
		return
	NotebookManager.update_page(page_id, page_name, page_text)

#endregion

#region Switching between editing and reading formatted text

func _on_text_edit_focus_exited() -> void:
	text_edit.hide()
	formatted_text.show()


func _on_formatted_text_gui_input(event: InputEvent) -> void:
	if event and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		formatted_text.hide()
		text_edit.show()
		text_edit.grab_focus()

#endregion
