extends CharacterBody2D

@export var move_speed := 500.0 #???
@export var tear_scene: PackedScene
@export var fire_rate:= 0.3 #seconds between shots
@export var dodge_duration := 0.1 #seconds (6 frames?)
@export var dodge_distance := 60.0 #pixels?
@export var dodge_speed := 1200.0 # ???

@onready var shoot_point: Marker2D = $ShootPoint
@onready var fire_timer: Timer = $FireCooldown

#var move_dir := Vector2.ZERO
var move_input_vector := Vector2.ZERO
var dodge_dir := Vector2.ZERO
var dodge_time := 0.0

func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true

func _physics_process(delta):
	handle_dodging()
	if dodge_time > 0:
		velocity = dodge_dir * dodge_speed
		dodge_time -= delta
		move_and_slide()
	else:
		handle_movement()
	
	handle_shooting()

func handle_movement():
	move_input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up") 
	)
	#move_dir = Vector2(
		#Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		#Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	#)
	
	if move_input_vector.length() > 0:
		move_input_vector = move_input_vector.normalized()
	
	velocity = move_input_vector.normalized() * move_speed
	move_and_slide()

func handle_dodging():
	var direction := Vector2.ZERO
	
	direction = move_input_vector
	if Input.is_action_just_released("dodge"): dodge(direction)

func handle_shooting():
	if fire_timer.time_left > 0:
		return
	
	var direction := get_shoot_direction()
	if direction == Vector2.ZERO:
		return
	
	shoot(direction)
	fire_timer.start()

func get_shoot_input() -> Vector2:
	if Input.is_action_pressed("shoot_up"):
		return Vector2.UP
	if Input.is_action_pressed("shoot_down"):
		return Vector2.DOWN
	if Input.is_action_pressed("shoot_left"):
		return Vector2.LEFT
	if Input.is_action_pressed("shoot_right"):
		return Vector2.RIGHT
	
	return Vector2.ZERO

func get_shoot_direction() -> Vector2:
	var shoot_dir = get_shoot_input()

	# If no shoot input at all → do NOT shoot
	if shoot_dir == Vector2.ZERO:
		return Vector2.ZERO

	# If moving diagonally, bias the shot
	if move_input_vector != Vector2.ZERO:
		if ((shoot_dir + move_input_vector) != Vector2.ZERO): 
			shoot_dir += move_input_vector
			shoot_dir = shoot_dir.normalized()

	return shoot_dir

func dodge(direction: Vector2):
	if direction == Vector2.ZERO: return

	dodge_dir = direction.normalized()
	dodge_time = dodge_duration
	#get_parent().global_position += direction.normalized() * dodge_distance

func shoot(direction: Vector2):
	var tear = tear_scene.instantiate()
	tear.global_position = shoot_point.global_position
	tear.direction = direction
	get_parent().add_child(tear)
