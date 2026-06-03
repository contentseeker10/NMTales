extends Node

var test_ui: TestUI

var math_ui_scene: PackedScene = preload("res://ui/menus/test/math/math_ui.tscn")
var lang_ui_scene: PackedScene
var hstr_ui_scene: PackedScene

enum TestType {
	Math,
	UkrLang,
	UkrHstr
}


func _unhandled_key_input(event: InputEvent) -> void:
	if test_ui and is_instance_valid(test_ui) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		end_test()


func start_test(test_type: TestType) -> void:
	get_tree().paused = true
	if test_type == TestType.Math:
		_init_math_ui()

func _init_math_ui() -> void:
	var math_ui: MathUI = math_ui_scene.instantiate()
	test_ui = math_ui
	get_tree().current_scene.add_child(math_ui)


func end_test() -> void:
	if test_ui and is_instance_valid(test_ui):
		test_ui.queue_free()
		test_ui = null
	get_tree().paused = false
