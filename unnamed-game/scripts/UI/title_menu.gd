extends Control

const BATTLE_SCENE_PATH := "res://scenes/Rooms/basic_room.tscn"

@onready var _main_container: CenterContainer = $MainContainer
@onready var _load_container: CenterContainer = $LoadContainer
@onready var _class_select_container: CenterContainer = $ClassSelectContainer

@onready var _continue_button: Button = %ContinueButton
@onready var _load_button: Button = %LoadButton
@onready var _slot_1_button: Button = %Slot1Button
@onready var _slot_2_button: Button = %Slot2Button
@onready var _slot_3_button: Button = %Slot3Button
@onready var _delete_slot_1_button: Button = %DeleteSlot1Button
@onready var _delete_slot_2_button: Button = %DeleteSlot2Button
@onready var _delete_slot_3_button: Button = %DeleteSlot3Button
@onready var _settings_menu: Control = %SettingsMenu

@onready var _class_buttons_container: VBoxContainer = %ClassButtonsContainer
@onready var _class_description: Label = %ClassDescription
@onready var _start_button: Button = %StartButton

var _new_game_mode := false
var _selected_class_id := ""


func _ready() -> void:
	GameState.load_settings()
	GameState.apply_audio_settings()
	_populate_class_buttons()
	_refresh_buttons()
	_show_panel(_main_container)
	_settings_menu.visible = false


func _populate_class_buttons() -> void:
	for child in _class_buttons_container.get_children():
		child.queue_free()
	for class_data in PlayerClasses.ALL_CLASSES:
		var btn := Button.new()
		btn.text = class_data["display_name"]
		btn.pressed.connect(_on_class_button_pressed.bind(class_data))
		_class_buttons_container.add_child(btn)


func _show_panel(panel: Control) -> void:
	_main_container.visible = (panel == _main_container)
	_load_container.visible = (panel == _load_container)
	_class_select_container.visible = (panel == _class_select_container)
	_settings_menu.visible = (panel == _settings_menu)


func _refresh_buttons() -> void:
	var has_saves := GameState.has_any_save()
	_continue_button.visible = has_saves
	_load_button.visible = has_saves
	var show_delete_buttons := not _new_game_mode
	_slot_1_button.text = "Slot 1 - %s" % GameState.get_save_summary(1).get("label", "Empty")
	_slot_2_button.text = "Slot 2 - %s" % GameState.get_save_summary(2).get("label", "Empty")
	_slot_3_button.text = "Slot 3 - %s" % GameState.get_save_summary(3).get("label", "Empty")
	_delete_slot_1_button.visible = show_delete_buttons
	_delete_slot_2_button.visible = show_delete_buttons
	_delete_slot_3_button.visible = show_delete_buttons
	_delete_slot_1_button.disabled = not GameState.has_save(1)
	_delete_slot_2_button.disabled = not GameState.has_save(2)
	_delete_slot_3_button.disabled = not GameState.has_save(3)


func _start_or_load_slot(slot: int) -> void:
	if _new_game_mode or not GameState.has_save(slot):
		GameState.create_new_run(slot)
		if not _selected_class_id.is_empty():
			GameState.current_run["class_id"] = _selected_class_id
		GameState.save_current_run(slot)
	else:
		if not GameState.load_run_from_slot(slot):
			return

	get_tree().change_scene_to_file(String(GameState.current_run.get("scene_path", BATTLE_SCENE_PATH)))


func _on_new_game_button_pressed() -> void:
	_selected_class_id = ""
	_start_button.disabled = true
	_class_description.text = ""
	_show_panel(_class_select_container)


func _on_continue_button_pressed() -> void:
	var slot := GameState.get_continue_slot()
	if slot < 1:
		return
	if not GameState.load_run_from_slot(slot):
		return
	get_tree().change_scene_to_file(String(GameState.current_run.get("scene_path", BATTLE_SCENE_PATH)))


func _on_load_button_pressed() -> void:
	_new_game_mode = false
	_refresh_buttons()
	_show_panel(_load_container)


func _on_settings_button_pressed() -> void:
	_show_panel(_settings_menu)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_slot_1_button_pressed() -> void:
	_start_or_load_slot(1)


func _on_slot_2_button_pressed() -> void:
	_start_or_load_slot(2)


func _on_slot_3_button_pressed() -> void:
	_start_or_load_slot(3)


func _on_back_from_load_pressed() -> void:
	_new_game_mode = false
	_show_panel(_main_container)


func _on_class_button_pressed(class_data: Dictionary) -> void:
	_selected_class_id = class_data["id"]
	_class_description.text = class_data["description"]
	_start_button.disabled = false


func _on_class_start_button_pressed() -> void:
	if _selected_class_id.is_empty():
		return
	_new_game_mode = true
	_refresh_buttons()
	_show_panel(_load_container)


func _on_back_from_class_select_pressed() -> void:
	_show_panel(_main_container)


func _on_settings_menu_closed() -> void:
	_refresh_buttons()
	_show_panel(_main_container)


func _delete_slot(slot: int) -> void:
	GameState.clear_slot(slot)
	_refresh_buttons()
	if not _new_game_mode and not GameState.has_any_save():
		_show_panel(_main_container)


func _on_delete_slot_1_button_pressed() -> void:
	_delete_slot(1)


func _on_delete_slot_2_button_pressed() -> void:
	_delete_slot(2)


func _on_delete_slot_3_button_pressed() -> void:
	_delete_slot(3)
