extends Area2D

@onready var _animated_sprite = $AnimatedSprite2D

@export var speed := 575.0
@export var tear_damage := 5.0
@export var range_distance := 400.0 #tear range (max distance able to travel) maybe move to player script later?

var direction := Vector2.ZERO
var distance_traveled := 0.0 #track distance traveled

func _ready():
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	_animated_sprite.play("spin")
	
	var movement = direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()
	
	if distance_traveled >= range_distance:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("player_hurtbox"):
		return

func _on_body_entered(body):
	if body.is_in_group("world"):
		queue_free()
		return
	
	if body.is_in_group("enemy"):
		body.take_damage(tear_damage)
		queue_free()
