extends Node

const SAVE_SLOT_COUNT := 3
const DEFAULT_BATTLE_SCENE := "res://scenes/Rooms/basic_room.tscn"

const _SETTINGS_PATH := "user://settings.json"
const _SAVE_PATH_TEMPLATE := "user://save_slot_%d.json"

var settings := {
	"last_save_slot": -1,
	"master_volume": 0.0,
	"music_volume": 0.0,
	"sfx_volume": 0.0,
}

var current_slot := -1
var current_run: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_audio_settings()


func slot_save_path(slot: int) -> String:
	return _SAVE_PATH_TEMPLATE % slot


func has_save(slot: int) -> bool:
	if slot < 1 or slot > SAVE_SLOT_COUNT:
		return false
	return FileAccess.file_exists(slot_save_path(slot))


func has_any_save() -> bool:
	for slot in range(1, SAVE_SLOT_COUNT + 1):
		if has_save(slot):
			return true
	return false


func get_continue_slot() -> int:
	var preferred := int(settings.get("last_save_slot", -1))
	if has_save(preferred):
		return preferred

	for slot in range(1, SAVE_SLOT_COUNT + 1):
		if has_save(slot):
			return slot

	return -1


func create_new_run(slot: int) -> Dictionary:
	current_slot = slot
	current_run = {
		"scene_path": DEFAULT_BATTLE_SCENE,
		"room_index": 0,
		"bosses_defeated": 0,
		"run_start_unix": Time.get_unix_time_from_system(),
		"updated_unix": Time.get_unix_time_from_system(),
	}
	return current_run


func update_current_run(scene_path: String, room_index: int, bosses_defeated: int) -> void:
	if current_run.is_empty():
		return
	current_run["scene_path"] = scene_path
	current_run["room_index"] = room_index
	current_run["bosses_defeated"] = bosses_defeated
	current_run["updated_unix"] = Time.get_unix_time_from_system()


func save_current_run(slot := -1, extra_data := {}) -> bool:
	if slot != -1:
		current_slot = slot

	if current_slot < 1 or current_slot > SAVE_SLOT_COUNT:
		return false
	if current_run.is_empty():
		return false

	var run_data := current_run.duplicate(true)
	for key in extra_data.keys():
		run_data[key] = extra_data[key]
	run_data["updated_unix"] = Time.get_unix_time_from_system()
	current_run = run_data

	var file := FileAccess.open(slot_save_path(current_slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(run_data))

	settings["last_save_slot"] = current_slot
	save_settings()
	return true


func load_run_from_slot(slot: int) -> bool:
	if not has_save(slot):
		return false

	var data := _read_json_file(slot_save_path(slot))
	if data.is_empty():
		return false

	current_slot = slot
	current_run = data
	settings["last_save_slot"] = slot
	save_settings()
	return true


func get_save_summary(slot: int) -> Dictionary:
	if not has_save(slot):
		return {
			"exists": false,
			"label": "Empty",
		}

	var data := _read_json_file(slot_save_path(slot))
	if data.is_empty():
		return {
			"exists": false,
			"label": "Empty",
		}

	var room_index := int(data.get("room_index", 0))
	var bosses_defeated := int(data.get("bosses_defeated", 0))
	var updated_unix := int(data.get("updated_unix", 0))
	var timestamp := "Unknown"
	if updated_unix > 0:
		timestamp = Time.get_datetime_string_from_unix_time(updated_unix, true)

	return {
		"exists": true,
		"label": "Room %d | Bosses %d | %s" % [room_index + 1, bosses_defeated, timestamp],
	}


func clear_slot(slot: int) -> void:
	if slot < 1 or slot > SAVE_SLOT_COUNT:
		return

	var save_path := slot_save_path(slot)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	if current_slot == slot:
		current_slot = -1
		current_run = {}

	if int(settings.get("last_save_slot", -1)) == slot:
		settings["last_save_slot"] = -1
		save_settings()


func clear_current_run(remove_saved_run := false) -> void:
	if remove_saved_run and current_slot >= 1:
		clear_slot(current_slot)
		return
	current_run = {}
	current_slot = -1


func load_settings() -> void:
	if not FileAccess.file_exists(_SETTINGS_PATH):
		return

	var data := _read_json_file(_SETTINGS_PATH)
	if data.is_empty():
		return

	for key in settings.keys():
		if data.has(key):
			settings[key] = data[key]


func save_settings() -> void:
	var file := FileAccess.open(_SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(settings))


func set_bus_volume(bus_name: String, value_db: float) -> void:
	var clamped_value := clampf(value_db, -40.0, 6.0)
	match bus_name:
		"Master":
			settings["master_volume"] = clamped_value
		"Music":
			settings["music_volume"] = clamped_value
		"SFX":
			settings["sfx_volume"] = clamped_value
		_:
			return

	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, clamped_value)

	save_settings()


func apply_audio_settings() -> void:
	set_bus_volume("Master", float(settings.get("master_volume", 0.0)))
	set_bus_volume("Music", float(settings.get("music_volume", 0.0)))
	set_bus_volume("SFX", float(settings.get("sfx_volume", 0.0)))


func get_current_scene_path() -> String:
	return String(current_run.get("scene_path", DEFAULT_BATTLE_SCENE))


func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed
