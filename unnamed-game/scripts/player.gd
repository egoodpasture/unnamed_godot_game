extends CharacterBody2D

@export var move_speed := 400.0 #???
@export var sprint_multiplier := 1.8
@export var tear_scene: PackedScene
@export var fire_rate:= 0.3 #seconds between shots

@export var max_health := 3

@export var dodge_duration := 0.15 #seconds (8 frames?)
@export var dodge_distance := 60.0 #pixels?
@export var dodge_speed := 1200.0 # ???
@export var dodge_tap_time := 0.25 #seconds

@onready var shoot_point: Marker2D = $ShootPoint
@onready var fire_timer: Timer = $FireCooldown

@onready var _player_sprite = $AnimatedPlayerSprite
@onready var _left_dodge = $DodgeSprites/LeftDodge
@onready var _right_dodge = $DodgeSprites/RightDodge

@onready var _death_sound = $Death/DeathSound
@onready var _death_animation = $Death/DeathAnimation

var health := max_health
var dead := false
var hit_invincibility_time := 0.8
var invincible := false
var dodge_invincible := false

var move_input_vector := Vector2.ZERO
var dodge_time := 0.0
var dodge_held_time := 0.0
var is_sprinting := false
var dodge_queued := false

func _ready():
	_player_sprite.play("idle")
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true

func _physics_process(delta):
	if dead: return
	
	handle_dodging(delta)
	
	if move_input_vector == Vector2.RIGHT: _player_sprite.flip_h = true
	elif move_input_vector == Vector2.LEFT: _player_sprite.flip_h = false
	if dodge_time > 0:
		velocity = move_input_vector * dodge_speed
		dodge_time -= delta
		if move_input_vector == Vector2.LEFT: _left_dodge.play("animate")
		if move_input_vector == Vector2.RIGHT: _right_dodge.play("animate")
		
		if dodge_time <= 0:
			end_dodge()
	else:
		handle_movement()
	
	move_and_slide()
	handle_shooting()

func handle_movement():
	move_input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up") 
	)

	if move_input_vector.length() > 0:
		move_input_vector = move_input_vector.normalized()
	if is_sprinting:
		velocity = move_input_vector * move_speed * sprint_multiplier
	else:
		velocity = move_input_vector.normalized() * move_speed

func handle_dodging(delta):
	if Input.is_action_just_pressed("dodge"):
		dodge_held_time = 0.0
		is_sprinting = false
		dodge_queued = true
	
	if Input.is_action_pressed("dodge"):
		dodge_held_time += delta
		
		if dodge_held_time >= dodge_tap_time:
			is_sprinting = true
			dodge_queued = false
	
	if Input.is_action_just_released("dodge"):
		if dodge_queued && !is_sprinting:
			dodge(move_input_vector)
		elif !dodge_queued && is_sprinting:
			is_sprinting = false

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

	dodge_time = dodge_duration
	dodge_invincible = true
	invincible = true
	$Hurtbox.set_deferred("monitoring", false)

func end_dodge():
	dodge_invincible = false
	invincible = false
	$Hurtbox.set_deferred("monitoring", true)

func shoot(direction: Vector2):
	var tear = tear_scene.instantiate()
	tear.global_position = shoot_point.global_position
	tear.direction = direction
	get_parent().add_child(tear)

func take_damage(amount: int):
	if invincible: return
	
	health -= amount
	if health <= 0:
		die()

	_player_sprite.modulate = Color.RED
	await get_tree().create_timer(.1).timeout
	_player_sprite.modulate = Color.WHITE
	
	invincible = true
	$Hurtbox.set_deferred("monitoring", false)
	
	# on hit i frames
	await get_tree().create_timer(hit_invincibility_time).timeout
	
	#only re enable if not dodging
	if not dodge_invincible:
		invincible = false
		$Hurtbox.set_deferred("monitoring", true)

func die():
	dead = true
	print ("player died xd")
	_player_sprite.visible = false
	_death_animation.play("explode")
	_death_sound.play()
	#_death_sound.stop()
	await get_tree().create_timer(.85).timeout
	
	queue_free()
