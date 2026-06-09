class_name PageContainer
extends MarginContainer

#region Node imports

@onready var name_edit: LineEdit = $VBoxContainer/NameEdit
@onready var text_edit: TextEdit = $VBoxContainer/TextEdit
@onready var name_edit_timer: Timer = $VBoxContainer/NameEdit/Timer
@onready var text_edit_timer: Timer = $VBoxContainer/TextEdit/Timer

#endregion

#region Backend specific vars

var page_id: int
var page_name: String
var page_text: String

#endregion


func _ready() -> void:
	name_edit.text = page_name
	text_edit.text = page_text


#region Signals processing

func _on_name_edit_text_changed(new_text: String) -> void:
	# TODO: Sends POST to server after 1 second delay...
	pass


func _on_text_edit_text_changed() -> void:
	# TODO: Sends POST to server after 1 second delay...
	pass

#endregion
