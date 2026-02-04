extends CharacterBody2D

@export var contact_damage := 1

signal died

func _ready():
	$Hitbox.area_entered.connect(_on_hitbox_entered)

func _on_hitbox_entered(area):
	if area.is_in_group("player_hurtbox"):
		var player = area.get_parent()
		player.take_damage(contact_damage)

func is_dead():
	died.emit()
	queue_free()
