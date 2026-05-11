extends Node2D


func _ready() -> void:
    if GameState.current_run.is_empty() and GameState.current_slot >= 1:
        GameState.create_new_run(GameState.current_slot)
    GameState.update_current_run(scene_file_path, 1, int(GameState.current_run.get("bosses_defeated", 0)))
    GameState.save_current_run()


func _on_return_to_title_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/UI/title_menu.tscn")
