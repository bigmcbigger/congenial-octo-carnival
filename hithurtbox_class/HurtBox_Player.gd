class_name HurtBox_Player
extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_layer = 0
	collision_mask = 2


func _on_area_entered(hitbox: HitBoxBasic):
	if hitbox == null:
		return
		
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage)
