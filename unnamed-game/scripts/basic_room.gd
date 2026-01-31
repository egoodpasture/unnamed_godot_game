extends Node2D

signal room_cleared

@export var enemy_scene: PackedScene
#@export var player_scene: PackedScene

var enemies_alive := 0

func _ready():
	#var player = player_scene.instantiate()
	#add_child(player)
	#player.global_position = $PlayerSpawn.global_position
	spawn_enemies()
	lock_doors()

func spawn_enemies():
	var spawns = $EnemySpawns.get_children()
	for spawn in spawns:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn.global_position
		add_child(enemy)
		enemies_alive += 1
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_alive -= 1
	if enemies_alive <= 0:
		clear_room()

func clear_room():
	unlock_doors()
	room_cleared.emit()

func lock_doors():
	for door in $Doors.get_children():
		door.set_deferred("monitoring", false)
		door.visible = false

func unlock_doors():
	for door in $Doors.get_children():
		door.set_deferred("monitoring", true)
		door.visible = true
