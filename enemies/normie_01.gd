extends Node3D

@onready var animation_player = $AnimationPlayer

var normie_max_health = 100
var normie_health = 100

func take_damage(amount: int):
	animation_player.play("hit")
	normie_health -= amount	
	$Healthbar3D.update(normie_health, normie_max_health)
