extends CharacterBody2D

enum BossState { IDLE, CHASE, ATTACK }

var state : BossState = BossState.IDLE
var player : CharacterBody2D

@export var max_health := 100.0
@export var move_speed := 100.0
@export var attack_range := 180.0
@export var aggro_range := 1200.0
@export var attack_cooldown := 1 #seconds

@export var contact_damage := 1
@export var sweep_damage := 1

@export var sweep_windup := .8 #seconds
@export var sweep_endlag := .6 #seconds
@export var sweep_angle := 235.0 #degrees
@export var sweep_duration := 0.5 #seconds
#@export var sweep_radius := 48.0

@export var dash_windup := 1 #seconds
@export var dash_distance := 400.0
@export var dash_buffer_distance := 48
@export var dash_speed := 200.0
@export var dash_arc_degrees := 60.0
@export var dash_arc_tear_count := 5
@export var dash_endlag := .6 #seconds

@export var tear_scene: PackedScene

@onready var boss_sprite: Sprite2D = $Sprite2D
@onready var death_sound = $Death/DeathSound
@onready var death_animation = $Death/DeathAnimation

var fight_start := true
var health := max_health
var dead := false

# All attack variables
var can_attack := true
var winding_up := false

# Sweep attack variables
var sweep_base_rotation := 0.0
var sweeping := false
var sweep_time := 0.0

# Dash attack variables
var dashing := false
var dash_direction := Vector2.ZERO
var dash_remaining_distance := 0.0
var dash_distance_traveled := 0.0
var dash_tear_interval := 0.0
var dash_next_tear_distance := 0.0
var dash_tear_direction := Vector2.ZERO
var dash_shoot_arc := false
var dash_arc_tear_index := 0

signal died

func _ready():
	player = get_tree().get_first_node_in_group("player")
	#$Hitbox.area_entered.connect(_on_hitbox_entered)
	$Sword/SweepAttack/SweepHitbox.area_entered.connect(_on_sweep_hit)

func _physics_process(delta):
	if dead: return
	if sweeping: 
		update_sweep(delta)
		return
	
	if dashing:
		update_dash(delta)
		return
	
	if winding_up:
		return
	
	if player == null: return
	
	match state: 
		BossState.IDLE:
			process_idle()
		BossState.CHASE:
			process_chase(delta)
		BossState.ATTACK:
			process_attack()

#func _on_hitbox_entered(area):
	#if area.is_in_group("player_hurtbox"):
		#area.get_parent().take_damage(contact_damage)

func _on_sweep_hit(area):
	if area.is_in_group("player_hurtbox"):
		area.get_parent().take_damage(sweep_damage)

func process_idle():
	if global_position.distance_to(player.global_position) <= aggro_range:
		state = BossState.CHASE

func process_chase(delta):
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	var distance = global_position.distance_to(player.global_position)
	if distance <= attack_range && can_attack:
		state = BossState.ATTACK

func process_attack():
	velocity = Vector2.ZERO
	if not can_attack or sweeping or dashing or winding_up:
		state = BossState.CHASE
		return
	
	can_attack = false
	
	if fight_start:
		fight_start = false
		start_dash_windup()
	elif randf() < 0.5:
		start_sweep_windup()
	else:
		start_dash_windup()

	state = BossState.CHASE

func start_attack_cooldown():
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func start_dash_windup():
	winding_up = true
	
	boss_sprite.modulate = Color.WEB_PURPLE
	
	await get_tree().create_timer(dash_windup).timeout
	
	start_dash()

func start_dash():
	winding_up = false
	boss_sprite.modulate = Color.WHITE
	
	var to_player := (player.global_position - global_position).normalized()
	
	var perpendicular_a := Vector2(-to_player.y, to_player.x)
	var perpendicular_b := Vector2(to_player.y, -to_player.x)
	var away_from_player := -to_player
	
	var required_clearance := dash_distance + dash_buffer_distance
	
	var can_dash_a := not test_move(global_transform, perpendicular_a * required_clearance)
	var can_dash_b := not test_move(global_transform, perpendicular_b * required_clearance)
	var can_dash_away := not test_move(global_transform, away_from_player * required_clearance)
	
	dash_shoot_arc = false
	
	if can_dash_a and can_dash_b:
		dash_direction = perpendicular_a if randf() < 0.5 else perpendicular_b
	elif can_dash_a:
		dash_direction = perpendicular_a
	elif can_dash_b:
		dash_direction = perpendicular_b
	elif can_dash_away:
		dash_direction = away_from_player
		dash_shoot_arc = true
	else:
		dashing = false
		dash_direction = Vector2.ZERO
		dash_remaining_distance = 0.0
		dash_distance_traveled = 0.0
		dash_next_tear_distance = 0.0
		dash_shoot_arc = false
		dash_arc_tear_index = 0
		
		shoot_full_dash_arc(to_player)
		
		start_attack_cooldown()
		start_dash_endlag()
		return
	
	dash_remaining_distance = dash_distance
	dash_distance_traveled = 0.0
	dash_tear_interval = dash_distance * 0.2
	dash_next_tear_distance = dash_tear_interval
	
	dash_tear_direction = to_player
	dash_arc_tear_index = 0
	
	dashing = true

func update_dash(delta):
	var move_distance: float = dash_speed * delta
	
	if move_distance >= dash_remaining_distance:
		move_distance = dash_remaining_distance
	
	velocity = dash_direction * (move_distance / delta)
	move_and_slide()
	
	dash_remaining_distance -= move_distance
	dash_distance_traveled += move_distance
	
	while dash_distance_traveled >= dash_next_tear_distance and dash_next_tear_distance <= dash_distance:
		if dash_shoot_arc:
			shoot_dash_arc_tear()
		else:
			shoot_dash_tear_pair()
		
		dash_next_tear_distance += dash_tear_interval
	
	if dash_remaining_distance <= 0:
		end_dash()

func end_dash():
	dashing = false
	dash_direction = Vector2.ZERO
	dash_remaining_distance = 0.0
	dash_distance_traveled = 0.0
	dash_next_tear_distance = 0.0
	dash_shoot_arc = false
	dash_arc_tear_index = 0
	velocity = Vector2.ZERO
	start_attack_cooldown()
	start_dash_endlag()
	
func start_dash_endlag():
	await get_tree().create_timer(dash_endlag).timeout

func start_sweep_windup():
	$Sword/Sprite2D.visible = true
	winding_up = true
	var to_player = (player.global_position - global_position).normalized()
	sweep_base_rotation = to_player.angle() + deg_to_rad(180)
	$Sword/Sprite2D.rotation = sweep_base_rotation + deg_to_rad(90)
	$Sword/SweepAttack.rotation = sweep_base_rotation
	
	boss_sprite.modulate = Color.DARK_ORANGE
	
	await get_tree().create_timer(sweep_windup).timeout
	
	boss_sprite.modulate = Color.WHITE
	
	winding_up = false
	start_sweep()

func start_sweep():
	sweeping = true
	sweep_time = 0.0

	$Sword/SweepAttack/SweepHitbox.monitoring = true

func update_sweep(delta):
	sweep_time += delta
	var t := sweep_time / sweep_duration
	
	if t >= 1:
		end_sweep()
		return
	
	var end_angle := deg_to_rad(sweep_angle)
	
	var local_angle = lerp(0.0, end_angle, t)
	$Sword/Sprite2D.rotation = sweep_base_rotation + local_angle + deg_to_rad(90)
	$Sword/SweepAttack.rotation = sweep_base_rotation + local_angle

func end_sweep():
	sweeping = false
	$Sword/Sprite2D.visible = false
	$Sword/SweepAttack/SweepHitbox.monitoring = false
	
	$Sword/Sprite2D.rotation = 0.0
	$Sword/SweepAttack.rotation = 0.0
	
	start_attack_cooldown()
	start_sweep_endlag()
	
func start_sweep_endlag():
	await get_tree().create_timer(sweep_endlag).timeout

func take_damage(amount: float):
	if dead: return
	health -= amount
	print("boss hit! current health: ", health)
	if health <= 0:
		die()
	
	boss_sprite.modulate = Color.RED
	await get_tree().create_timer(.1).timeout
	boss_sprite.modulate = Color.WHITE

func shoot_dash_tear_pair():
	shoot_boss_tear(dash_tear_direction)
	shoot_boss_tear(-dash_tear_direction)

func shoot_full_dash_arc(base_direction: Vector2):
	dash_tear_direction = base_direction.normalized()
	dash_arc_tear_index = 0
	
	for i in range(dash_arc_tear_count):
		shoot_dash_arc_tear()

func shoot_dash_arc_tear():
	if dash_arc_tear_index >= dash_arc_tear_count:
		return
	
	var base_angle := dash_tear_direction.angle()
	var arc_start := -dash_arc_degrees / 2.0
	var angle_step := dash_arc_degrees / float(dash_arc_tear_count - 1)
	var angle_offset := arc_start + angle_step * dash_arc_tear_index
	
	var tear_direction := Vector2.RIGHT.rotated(base_angle + deg_to_rad(angle_offset))
	shoot_boss_tear(tear_direction)
	
	dash_arc_tear_index += 1

func shoot_boss_tear(direction: Vector2):
	if tear_scene == null:
		return
	
	var tear = tear_scene.instantiate()
	tear.global_position = global_position + direction.normalized() * 64.0
	tear.direction = direction.normalized()
	tear.source = "boss"
	get_parent().add_child(tear)

func die():
	dead = true
	died.emit()
	boss_sprite.visible = false
	
	death_animation.play("explode")
	death_sound.play()
	#_death_sound.stop()
	await get_tree().create_timer(.85).timeout
	
	queue_free()
	queue_free()
