extends Node3D

@export var enemy_01: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	var mob_01 = enemy_01.instantiate()
	var mob_02 = enemy_01.instantiate()
	var mob_03 = enemy_01.instantiate()
	
	# TODO: Create spawn zones. Right now, we're hardcoding positions
	mob_01.spawn_at(Vector3(0,0,200))
	mob_02.spawn_at(Vector3(-8,0,220))
	mob_03.spawn_at(Vector3(25,0,203))
	
	add_child(mob_01)
	add_child(mob_02)
	add_child(mob_03)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
