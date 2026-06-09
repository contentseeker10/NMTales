class_name NotebookScreen
extends CanvasLayer

#region Maintenance vars

var _page_container_scene: PackedScene = preload("res://ui/menus/notebook/page_container/page_container.tscn")

#endregion

#region Node imports

@onready var page_list: VBoxContainer = $PanelContainer/PanelContainer/PageListContainer
@onready var tab_bar: TabBar = $PanelContainer/PanelContainer/PageListContainer/TabBar

#endregion


func _ready() -> void:
	_load_pages()

func _load_pages() -> void:
	var pages_data: Array = await NotebookManager.load_pages()
	for data in pages_data:
		_init_page(data)


#region Page add/change handler

func _on_tab_bar_tab_selected(tab: int) -> void:
	if tab == tab_bar.tab_count - 1:
		if tab_bar.tab_count == 10:
			return
		_create_new_page()
	else:
		_change_page_to(tab + 1)

func _create_new_page() -> void:
	var page_data: Dictionary = await NotebookManager.create_page("Page " + str(tab_bar.tab_count))
	if page_data.is_empty():
		return
	_init_page(page_data)
	_change_page_to(tab_bar.tab_count - 1)

func _init_page(page_data: Dictionary) -> void:
	var page: PageContainer = _page_container_scene.instantiate()
	page.page_id = page_data.get("id", -1)
	page.page_name = page_data.get("title", "error")
	page.page_text = page_data.get("content", "error")
	page.index = tab_bar.tab_count
	page_list.add_child(page)
	page.title_changed.connect(func(new_title): 
		tab_bar.set_tab_title(page.index - 1, new_title))
	page.delete_button.pressed.connect(_on_delete_button_pressed.bind(page))
	_add_new_tab(page.page_name)

func _add_new_tab(title: String) -> void:
	tab_bar.add_tab(title)
	tab_bar.move_tab(tab_bar.tab_count - 1, tab_bar.tab_count - 2)
	tab_bar.current_tab = tab_bar.tab_count - 2
	if tab_bar.tab_count == 10:
		tab_bar.set_tab_disabled(tab_bar.tab_count - 1, true)

func _change_page_to(index: int) -> void:
	for page in page_list.get_children():
		if page and page is PageContainer:
			if page.index == index:
				page.show()
			else:
				page.hide()

#endregion


#region Page deletion

func _on_delete_button_pressed(page: PageContainer) -> void:
	NotebookManager.delete_page(page.page_id)
	_recount_indexes(page.index)
	tab_bar.remove_tab(page.index - 1)
	if tab_bar.tab_count > 1:
		tab_bar.current_tab = 0
		_change_page_to(1)
	else:
		tab_bar.current_tab = -1
	if tab_bar.tab_count < 10:
		tab_bar.set_tab_disabled(tab_bar.tab_count - 1, false)
	page.queue_free()

func _recount_indexes(from: int) -> void:
	for page in page_list.get_children():
		if page and page is PageContainer:
			if page.index > from:
				page.index -= 1

#endregion
