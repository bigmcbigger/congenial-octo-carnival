extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var health_text_3d = $Label3D

var normie_health = 100

func take_damage(amount: int):
	animation_player.play("hit")
	normie_health -= amount	
	health_text_3d.text = str(normie_health)
