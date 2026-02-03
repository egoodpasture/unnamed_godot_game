extends Area2D

@onready var _animated_sprite = $AnimatedSprite2D

@export var speed := 575.0
@export var lifetime := 2.0

var direction := Vector2.ZERO

func _ready():
	rotation = direction.angle()
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	_animated_sprite.play("spin")
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		body.take_damage(1)
		queue_free()
