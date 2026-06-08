class_name NotebookScreen
extends CanvasLayer

#region Maintenance vars

var _page_container_scene: PackedScene = preload("res://ui/menus/notebook/page_container/page_container.tscn")

#endregion

#region Node imports

@onready var tab_bar: TabBar = $PanelContainer/PanelContainer/VBoxContainer/TabBar
@onready var page_list: Control = $PanelContainer/PanelContainer/VBoxContainer/PageList

#endregion


#region Page add/change handler

func _on_tab_bar_tab_selected(tab: int) -> void:
	if tab == -1:
		_create_new_page()
	else:
		_change_page_to(tab)

func _create_new_page() -> void:
	_add_new_tab()
	# TODO: Instantiating new page from scene...

func _add_new_tab() -> void:
	# TODO: Adds new tab to TabBar right before "add"...
	pass

func _change_page_to(index: int) -> void:
	# TODO: Hides last page container and shows selected one...
	pass

#endregion
