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

@onready var boss_sprite: Sprite2D = $Sprite2D
@onready var death_sound = $Death/DeathSound
@onready var death_animation = $Death/DeathAnimation

var health := max_health
var dead := false

var can_attack := true

var winding_up := false
var sweep_base_rotation := 0.0
var sweeping := false
var sweep_time := 0.0

signal died

func _ready():
	player = get_tree().get_first_node_in_group("player")
	$Hitbox.area_entered.connect(_on_hitbox_entered)
	$Sword/SweepAttack/SweepHitbox.area_entered.connect(_on_sweep_hit)

func _physics_process(delta):
	if dead: return
	if sweeping: 
		update_sweep(delta)
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

func _on_hitbox_entered(area):
	if area.is_in_group("player_hurtbox"):
		area.get_parent().take_damage(contact_damage)

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
	if not can_attack or sweeping or winding_up:
		state = BossState.CHASE
		return
	
	can_attack = false
	start_sweep_windup()
	state = BossState.CHASE

func start_attack_cooldown():
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

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
