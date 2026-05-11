extends Node2D

signal room_cleared

@export var enemy_scene: PackedScene
@export var next_room_scene: PackedScene = preload("res://scenes/Rooms/empty_room.tscn")
@export var settings_menu_scene: PackedScene = preload("res://scenes/UI/settings_menu.tscn")
@export var door_sprite_texture: Texture2D = preload("res://assets/sprites/placeholder_door.svg")
@export var title_scene_path := "res://scenes/UI/title_menu.tscn"
@export var room_music: AudioStream

const BOSS_ROOM_INDEX := 0
const NEXT_ROOM_INDEX := 1

var enemies_alive := 0
var battle_finished := false
var battle_won := false
var run_start_unix := 0

@onready var _door_area: Area2D = $Doors/Area2D
@onready var _player: Node = $Player

var _pause_menu: Panel
var _game_over_panel: Panel
var _battle_label: Label
var _stats_label: Label
var _settings_menu: Control
var _music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if GameState.current_run.is_empty() and GameState.current_slot >= 1:
		GameState.create_new_run(GameState.current_slot)
	run_start_unix = int(GameState.current_run.get("run_start_unix", Time.get_unix_time_from_system()))

	if not GameState.current_run.is_empty():
		var bosses := int(GameState.current_run.get("bosses_defeated", 0))
		GameState.update_current_run(scene_file_path, BOSS_ROOM_INDEX, bosses)

	# Explicitly pausable so they stop when the tree is paused
	if is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		if _player.has_signal("died"):
			_player.died.connect(_on_player_died)

	_build_ui()
	_setup_door()
	spawn_enemies()
	lock_doors()
	_setup_music()
	_show_battle_text("BATTLE START")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not battle_finished:
		_toggle_pause_menu()


func spawn_enemies() -> void:
	enemies_alive = 0
	for spawn in $EnemySpawns.get_children():
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn.global_position
		# Explicitly pausable so enemies stop when the tree is paused
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(enemy)
		enemies_alive += 1
		enemy.died.connect(_on_enemy_died)


func _setup_door() -> void:
	_door_area.body_entered.connect(_on_door_body_entered)
	var door_sprite := _door_area.get_node_or_null("DoorSprite") as Sprite2D
	if door_sprite == null:
		door_sprite = Sprite2D.new()
		door_sprite.name = "DoorSprite"
		_door_area.add_child(door_sprite)
	door_sprite.texture = door_sprite_texture
	door_sprite.z_index = 5


func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		clear_room()


func clear_room() -> void:
	if battle_finished:
		return

	battle_finished = true
	battle_won = true
	unlock_doors()
	room_cleared.emit()

	var bosses := int(GameState.current_run.get("bosses_defeated", 0)) + 1
	GameState.update_current_run(next_room_scene.resource_path, NEXT_ROOM_INDEX, bosses)
	GameState.save_current_run(GameState.current_slot, {"in_battle": false})

	_show_battle_text("VICTORY! Door opened.")


func lock_doors() -> void:
	_door_area.set_deferred("monitoring", false)
	_door_area.visible = false


func unlock_doors() -> void:
	_door_area.set_deferred("monitoring", true)
	_door_area.visible = true


func _on_door_body_entered(body: Node) -> void:
	if not battle_won:
		return
	if not body.is_in_group("player"):
		return

	get_tree().call_deferred("change_scene_to_packed", next_room_scene)


func _on_player_died() -> void:
	if battle_finished:
		return

	battle_finished = true
	battle_won = false
	get_tree().paused = true
	_show_game_over()


func _build_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 20
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	_battle_label = Label.new()
	_battle_label.name = "BattleLabel"
	_battle_label.process_mode = Node.PROCESS_MODE_ALWAYS
	_battle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_battle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_battle_label.anchor_left = 0.5
	_battle_label.anchor_top = 0.08
	_battle_label.anchor_right = 0.5
	_battle_label.anchor_bottom = 0.08
	_battle_label.offset_left = -300
	_battle_label.offset_right = 300
	ui_layer.add_child(_battle_label)

	_pause_menu = _create_pause_menu()
	_pause_menu.visible = false
	_pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui_layer.add_child(_pause_menu)

	_game_over_panel = _create_game_over_panel()
	_game_over_panel.visible = false
	_game_over_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	ui_layer.add_child(_game_over_panel)

	_settings_menu = settings_menu_scene.instantiate()
	_settings_menu.visible = false
	_settings_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_settings_menu.closed.connect(_on_settings_menu_closed)
	ui_layer.add_child(_settings_menu)


func _create_pause_menu() -> Panel:
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_top = -210
	panel.offset_right = 220
	panel.offset_bottom = 210

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 16
	margin.offset_top = 16
	margin.offset_right = -16
	margin.offset_bottom = -16
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_button := Button.new()
	resume_button.text = "Resume"
	resume_button.pressed.connect(_on_resume_button_pressed)
	vbox.add_child(resume_button)

	var save_quit_button := Button.new()
	save_quit_button.text = "Save and Quit"
	save_quit_button.pressed.connect(_on_save_and_quit_button_pressed)
	vbox.add_child(save_quit_button)

	var abandon_button := Button.new()
	abandon_button.text = "Abandon Run"
	abandon_button.pressed.connect(_on_abandon_run_button_pressed)
	vbox.add_child(abandon_button)

	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.pressed.connect(_on_pause_settings_button_pressed)
	vbox.add_child(settings_button)

	return panel


func _create_game_over_panel() -> Panel:
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_top = -180
	panel.offset_right = 260
	panel.offset_bottom = 180

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 16
	margin.offset_top = 16
	margin.offset_right = -16
	margin.offset_bottom = -16
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_stats_label = Label.new()
	_stats_label.text = "Run stats unavailable"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_stats_label)

	var return_button := Button.new()
	return_button.text = "Return to Title"
	return_button.pressed.connect(_on_return_to_title_pressed)
	vbox.add_child(return_button)

	return panel


func _toggle_pause_menu() -> void:
	if get_tree().paused:
		_settings_menu.visible = false
		_pause_menu.visible = false
		get_tree().paused = false
		if is_instance_valid(_music_player):
			_music_player.stream_paused = false
		return

	get_tree().paused = true
	_pause_menu.visible = true
	if is_instance_valid(_music_player):
		_music_player.stream_paused = true


func _show_battle_text(text: String) -> void:
	_battle_label.text = text
	_battle_label.visible = true
	await get_tree().create_timer(1.4, true, false, true).timeout
	if is_instance_valid(_battle_label):
		_battle_label.visible = false


func _show_game_over() -> void:
	var elapsed: int = maxi(0, int(Time.get_unix_time_from_system()) - run_start_unix)
	var bosses: int = int(GameState.current_run.get("bosses_defeated", 0))
	_stats_label.text = "Placeholder Run Stats\nTime Survived: %ds\nBosses Defeated: %d" % [elapsed, bosses]
	_game_over_panel.visible = true
	if GameState.current_slot >= 1:
		GameState.clear_slot(GameState.current_slot)


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	_pause_menu.visible = false
	if is_instance_valid(_music_player):
		_music_player.stream_paused = false


func _on_save_and_quit_button_pressed() -> void:
	if not GameState.current_run.is_empty():
		var bosses := int(GameState.current_run.get("bosses_defeated", 0))
		GameState.update_current_run(scene_file_path, BOSS_ROOM_INDEX, bosses)
		GameState.save_current_run(GameState.current_slot, {"in_battle": true})
	get_tree().paused = false
	if is_instance_valid(_music_player):
		_music_player.stop()
	get_tree().change_scene_to_file(title_scene_path)


func _on_abandon_run_button_pressed() -> void:
	if GameState.current_slot >= 1:
		GameState.clear_slot(GameState.current_slot)
	else:
		GameState.clear_current_run()
	get_tree().paused = false
	if is_instance_valid(_music_player):
		_music_player.stop()
	get_tree().change_scene_to_file(title_scene_path)


func _on_pause_settings_button_pressed() -> void:
	_pause_menu.visible = false
	_settings_menu.visible = true


func _on_settings_menu_closed() -> void:
	if get_tree().paused and not battle_finished:
		_pause_menu.visible = true


func _setup_music() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = room_music
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	if room_music != null:
		_music_player.play()


func _on_return_to_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(title_scene_path)
