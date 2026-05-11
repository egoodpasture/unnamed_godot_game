extends Control

const BATTLE_SCENE_PATH := "res://scenes/Rooms/basic_room.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _load_panel: Panel = %LoadPanel
@onready var _slot_1_button: Button = %Slot1Button
@onready var _slot_2_button: Button = %Slot2Button
@onready var _slot_3_button: Button = %Slot3Button
@onready var _settings_menu: Control = %SettingsMenu


func _ready() -> void:
    GameState.load_settings()
    GameState.apply_audio_settings()
    _refresh_buttons()
    _load_panel.visible = false
    _settings_menu.visible = false


func _refresh_buttons() -> void:
    _continue_button.disabled = not GameState.has_any_save()
    _slot_1_button.text = "Slot 1 - %s" % GameState.get_save_summary(1).get("label", "Empty")
    _slot_2_button.text = "Slot 2 - %s" % GameState.get_save_summary(2).get("label", "Empty")
    _slot_3_button.text = "Slot 3 - %s" % GameState.get_save_summary(3).get("label", "Empty")


func _start_or_load_slot(slot: int) -> void:
    if GameState.has_save(slot):
        if not GameState.load_run_from_slot(slot):
            return
    else:
        GameState.create_new_run(slot)
        GameState.save_current_run(slot)

    get_tree().change_scene_to_file(String(GameState.current_run.get("scene_path", BATTLE_SCENE_PATH)))


func _on_continue_button_pressed() -> void:
    var slot := GameState.get_continue_slot()
    if slot < 1:
        return
    if not GameState.load_run_from_slot(slot):
        return
    get_tree().change_scene_to_file(String(GameState.current_run.get("scene_path", BATTLE_SCENE_PATH)))


func _on_load_button_pressed() -> void:
    _refresh_buttons()
    _load_panel.visible = true


func _on_settings_button_pressed() -> void:
    _settings_menu.visible = true


func _on_quit_button_pressed() -> void:
    get_tree().quit()


func _on_slot_1_button_pressed() -> void:
    _start_or_load_slot(1)


func _on_slot_2_button_pressed() -> void:
    _start_or_load_slot(2)


func _on_slot_3_button_pressed() -> void:
    _start_or_load_slot(3)


func _on_back_from_load_pressed() -> void:
    _load_panel.visible = false


func _on_settings_menu_closed() -> void:
    _refresh_buttons()
