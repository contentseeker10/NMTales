## A container UI element that represents a single notebook page.
##
## Allows viewing and editing of the page name/title and its body text. It automatically
## saves changes to the [NotebookManager] after a brief debounce period and coordinates
## UI state transitions between reading formatted text and editing raw text.
class_name PageContainer
extends MarginContainer

## ID used to debounce page name updates.
var _name_change_id: int = 0
## ID used to debounce page text updates.
var _text_change_id: int = 0

#region Node imports

## LineEdit used for modifying the page title.
@onready var name_edit: LineEdit = $VBoxContainer/HFlowContainer/NameEdit
## TextEdit used for editing the raw text content of the page.
@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
## RichTextLabel used for displaying formatted/parsed text when not editing.
@onready var formatted_text: RichTextLabel = $VBoxContainer/FormattedText

## Debounce timer for page name edits.
@onready var name_edit_timer: Timer = $VBoxContainer/HFlowContainer/NameEdit/Timer
## Debounce timer for page content text edits.
@onready var text_edit_timer: Timer = $VBoxContainer/TextEdit/Timer

## Button to delete the current page.
@onready var delete_button: Button = $VBoxContainer/HFlowContainer/DeleteButton

#endregion

#region Backend specific vars

## The backend database ID of the page.
var page_id: int
## The title/name of the page.
var page_name: String
## The body content of the page.
var page_text: String

#endregion

## The index of this page in the notebook list.
var index: int


## Initializes the UI controls with the page's current name and text.
func _ready() -> void:
	name_edit.text = page_name
	text_edit.text = page_text
	formatted_text.text = page_text


#region Updating data to backend

## Called when the text in the name edit field changes. Debounces and updates the page title in the backend.
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


## Called when the text in the text edit field changes. Debounces and updates the page content in the backend.
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

## Swaps the TextEdit out and shows the RichTextLabel formatted text when focus is lost.
func _on_text_edit_focus_exited() -> void:
	text_edit.hide()
	formatted_text.show()


## Enables editing mode when the formatted text label is left-clicked.
func _on_formatted_text_gui_input(event: InputEvent) -> void:
	if event and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		formatted_text.hide()
		text_edit.show()
		text_edit.grab_focus()

#endregion

