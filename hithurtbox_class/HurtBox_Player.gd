class_name HurtBox_Player
extends Area3D

func _ready():
	collision_layer = 0
	collision_mask = 3

func _on_area_entered(hitbox: HitBox_Enemy):
	if hitbox == null:
		return
		
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage, hitbox.global_position)
