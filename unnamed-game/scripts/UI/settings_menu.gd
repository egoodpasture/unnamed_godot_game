extends Control

signal closed

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider


func _ready() -> void:
    _master_slider.value = float(GameState.settings.get("master_volume", 0.0))
    _music_slider.value = float(GameState.settings.get("music_volume", 0.0))
    _sfx_slider.value = float(GameState.settings.get("sfx_volume", 0.0))

    _master_slider.value_changed.connect(_on_master_slider_changed)
    _music_slider.value_changed.connect(_on_music_slider_changed)
    _sfx_slider.value_changed.connect(_on_sfx_slider_changed)


func _on_master_slider_changed(value: float) -> void:
    GameState.set_bus_volume("Master", value)


func _on_music_slider_changed(value: float) -> void:
    GameState.set_bus_volume("Music", value)


func _on_sfx_slider_changed(value: float) -> void:
    GameState.set_bus_volume("SFX", value)


func _on_back_button_pressed() -> void:
    visible = false
    closed.emit()
