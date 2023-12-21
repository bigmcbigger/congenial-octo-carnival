extends Node3D

var player_maxhealth = 100

func take_damage(amount: int):
	#animation_player.play("hit")
	var health = player_maxhealth
	health -= amount
	$Healthbar3D.update(health, player_maxhealth)
