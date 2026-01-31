extends CharacterBody2D

@export var move_speed := 500.0
@export var tear_scene: PackedScene
@export var fire_rate:= 0.35 #seconds between shots

@onready var shoot_point: Marker2D = $ShootPoint
@onready var fire_timer: Timer = $FireCooldown

func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true

func _physics_process(delta):
	handle_movement()
	handle_shooting()

func handle_movement():
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up") 
	)
	
	velocity = input_vector.normalized() * move_speed
	move_and_slide()

func handle_shooting():
	if fire_timer.time_left > 0:
		return
	
	var direction := get_shoot_direction()
	if direction == Vector2.ZERO:
		return
	
	shoot(direction)
	fire_timer.start()

func get_shoot_direction() -> Vector2:
	if Input.is_action_pressed("shoot_up"):
		return Vector2.UP
	if Input.is_action_pressed("shoot_down"):
		return Vector2.DOWN
	if Input.is_action_pressed("shoot_left"):
		return Vector2.LEFT
	if Input.is_action_pressed("shoot_right"):
		return Vector2.RIGHT
	
	return Vector2.ZERO

func shoot(direction: Vector2):
	var tear = tear_scene.instantiate()
	tear.global_position = shoot_point.global_position
	tear.direction = direction
	get_parent().add_child(tear)
