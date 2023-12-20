extends CharacterBody3D

# TODO set target on enter leash zone
@onready var navigation_agent = $NavigationAgent3D

func _ready():
	call_deferred("deferred")

func deferred():
	await get_tree().physics_frame
	navigation_agent.set_target_position(Vector3(0,0,0))

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()

	velocity = current_position.direction_to(next_path_position) * 10.0
	move_and_slide()
