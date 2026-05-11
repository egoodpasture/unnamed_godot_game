extends Area2D

@onready var _animated_sprite = $AnimatedSprite2D

@export var speed := 575.0
@export var player_tear_damage := 2.0
@export var boss_tear_damage := 1.0
@export var range_distance := 400.0

var direction := Vector2.ZERO
var distance_traveled := 0.0
var source := "player"
var has_hit := false

func _ready():
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	_animated_sprite.play("spin")
	
	var movement = direction * speed * delta
	global_position += movement
	
	if source == "player":
		distance_traveled += movement.length()
		if distance_traveled >= range_distance:
			queue_free()

func _on_area_entered(area):
	if has_hit:
		return

	if source == "boss" and area.is_in_group("player_hurtbox"):
		has_hit = true
		area.get_parent().take_damage(boss_tear_damage)
		queue_free()
		return

	if source == "player" and area.is_in_group("enemy_hurtbox"):
		has_hit = true
		area.get_parent().take_damage(player_tear_damage)
		queue_free()
		return

func _on_body_entered(body):
	if has_hit:
		return

	if body.is_in_group("world"):
		has_hit = true
		queue_free()
		return
