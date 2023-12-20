extends CharacterBody3D

# TODO set target on enter leash zone
var navigation_agent = null
var navmap_ready = false
var player = null

func _ready():
	call_deferred("deferred")
	player = get_tree().current_scene.get_node("Player")
	navigation_agent = $navigation_point.get_node("NavigationAgent3D")
	navigation_agent.target_desired_distance = 2.0;
	navigation_agent.path_desired_distance = 2.0;

func deferred():
	await get_tree().physics_frame
	navmap_ready = true
	
func _process(delta):
	if navmap_ready:
		if not navigation_agent.is_navigation_finished():
			# currently pathing, TODO update target if needed
			if navigation_agent.target_position.distance_to(player.global_position) > 2.0:
				navigation_agent.set_target_position(player.global_position)
		else:
			# need target, TODO set valid target if needed
			# TODO can ignore y position
			navigation_agent.set_target_position(player.global_position)
			pass

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()

	velocity = current_position.direction_to(next_path_position) * 8.0;
	velocity.y = 0.0;
	move_and_slide()
