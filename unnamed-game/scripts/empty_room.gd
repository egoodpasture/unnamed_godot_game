extends Node2D

const EMPTY_ROOM_INDEX := 1

@export var room_music: AudioStream

func _ready() -> void:
	if GameState.current_run.is_empty() and GameState.current_slot >= 1:
		GameState.create_new_run(GameState.current_slot)
	GameState.update_current_run(scene_file_path, EMPTY_ROOM_INDEX, int(GameState.current_run.get("bosses_defeated", 0)))
	GameState.save_current_run()
	_setup_music()


func _setup_music() -> void:
	if room_music == null:
		return
	var music_player := AudioStreamPlayer.new()
	music_player.stream = room_music
	music_player.bus = "Music"
	add_child(music_player)
	music_player.play()


func _on_return_to_title_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UI/title_menu.tscn")
