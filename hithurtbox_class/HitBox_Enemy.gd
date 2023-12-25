class_name HitBox_Enemy
extends Area3D

@export var damage = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_layer = 3
	collision_mask = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
