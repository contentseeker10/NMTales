## Controller for the Notebook UI screen.
## Manages creation, deletion, display, and tab switching of notebook pages,
## coordinating between UI controls and the NotebookManager singleton.
class_name NotebookScreen
extends CanvasLayer

#region Maintenance vars

## PackedScene used to instantiate page containers.
var _page_container_scene: PackedScene = preload("res://ui/menus/notebook/page_container/page_container.tscn")

#endregion

#region Node imports

## Container node holding all page container instances.
@onready var page_list: VBoxContainer = $PanelContainer/PanelContainer/PageListContainer
## TabBar node managing page tab selection.
@onready var tab_bar: TabBar = $PanelContainer/PanelContainer/PageListContainer/TabBar

#endregion


## Connects to relevant event bus signals and loads existing pages.
func _ready() -> void:
	EventBus.page_title_changed.connect(_on_page_title_changed)
	_load_pages()

## Asynchronously loads saved pages from the NotebookManager and initializes them.
func _load_pages() -> void:
	var pages_data: Array = await NotebookManager.load_pages()
	for data in pages_data:
		_init_page(data)


#region Page add/change handler

## Handles tab selection events. Switches to the selected page or,
## if the "add new" tab is selected, creates a new page.
func _on_tab_bar_tab_selected(tab: int) -> void:
	if tab == tab_bar.tab_count - 1:
		if tab_bar.tab_count == 10:
			return
		_create_new_page()
	else:
		_change_page_to(tab + 1)

## Asynchronously requests the creation of a new page from NotebookManager,
## initializes it, and switches focus to it.
func _create_new_page() -> void:
	var page_data: Dictionary = await NotebookManager.create_page("Сторінка " + str(tab_bar.tab_count))
	if page_data.is_empty():
		return
	_init_page(page_data)
	_change_page_to(tab_bar.tab_count - 1)

## Instantiates a new page container with the provided page data,
## adds it to the page list, binds its deletion signal, and creates a corresponding tab.
func _init_page(page_data: Dictionary) -> void:
	var page: PageContainer = _page_container_scene.instantiate()
	page.page_id = page_data.get("id", -1)
	page.page_name = page_data.get("title", "error")
	page.page_text = page_data.get("content", "error")
	page.index = tab_bar.tab_count
	page_list.add_child(page)
	page.delete_button.pressed.connect(_on_delete_button_pressed.bind(page))
	_add_new_tab(page.page_name)

## Adds a tab representing a new page, manages tab insertion order,
## and disables the "add new" tab if the limit of 10 pages is reached.
func _add_new_tab(title: String) -> void:
	tab_bar.add_tab(title)
	tab_bar.move_tab(tab_bar.tab_count - 1, tab_bar.tab_count - 2)
	tab_bar.current_tab = tab_bar.tab_count - 2
	if tab_bar.tab_count == 10:
		tab_bar.set_tab_disabled(tab_bar.tab_count - 1, true)

## Switches visibility of page containers so only the page at the given index is visible.
func _change_page_to(index: int) -> void:
	for page in page_list.get_children():
		if page and page is PageContainer:
			if page.index == index:
				page.show()
			else:
				page.hide()


## Callback handler for when a page's title is changed. Updates the matching tab title.
func _on_page_title_changed(index: int, new_title: String) -> void:
	tab_bar.set_tab_title(index - 1, new_title)

#endregion


#region Page deletion

## Deletes the page container, notifies NotebookManager, updates remaining pages' indexes,
## removes the tab, and adjusts active tab selection.
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

## Adjusts the index of pages positioned after the deleted page.
func _recount_indexes(from: int) -> void:
	for page in page_list.get_children():
		if page and page is PageContainer:
			if page.index > from:
				page.index -= 1

#endregion


## Hides the notebook screen and resumes game execution.
func _on_notebook_button_pressed() -> void:
	self.hide()
	get_tree().paused = false
