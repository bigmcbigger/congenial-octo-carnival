extends CharacterBody3D

# TODO set target on enter leash zone
enum NAV_STATE {MOVING, BEGIN_ATTACK, ATTACKING, WAITING}

@export var ATTACK_CANCEL_RANGE: float = 3.0
@export var ATTACK_BEGIN_RANGE: float = 2.0
@export var MOVE_SPEED: float = 8.0
@export var AGGRO_RANGE: float = 20.0
@export var ATTACK_DURATION: float = 1.0;

var navmap_ready = false
var nav_state = NAV_STATE.WAITING
var player = null

@onready var navigation_agent = $navigation_point/NavigationAgent3D
@onready var attack_timer = $attack_timer

func _ready():
	call_deferred("deferred")
	player = get_tree().current_scene.get_node("Player")
	navigation_agent.target_desired_distance = ATTACK_BEGIN_RANGE;
	navigation_agent.path_desired_distance = ATTACK_BEGIN_RANGE;

func deferred():
	await get_tree().physics_frame
	navmap_ready = true
	

func update_navigation_state() -> NAV_STATE:
	if not navmap_ready:
		return NAV_STATE.WAITING
	# NOTE: should use xz coords only for distance testing.
	var player_pos = player.global_position
	var agent_pos = $navigation_point.global_position
	match nav_state:
		NAV_STATE.MOVING:
			if navigation_agent.is_navigation_finished():
				if agent_pos.distance_to(player_pos) > ATTACK_CANCEL_RANGE:
					navigation_agent.set_target_position(player_pos)
					return NAV_STATE.MOVING
				else:
					return NAV_STATE.BEGIN_ATTACK
			else:
				var target_pos = navigation_agent.target_position
				if target_pos.distance_to(player_pos) > ATTACK_BEGIN_RANGE:
					# Target position would be outside of begin range, find
					# a new position
					navigation_agent.set_target_position(player_pos)
			return NAV_STATE.MOVING
		NAV_STATE.BEGIN_ATTACK:
			attack_timer.start(ATTACK_DURATION)
			return NAV_STATE.ATTACKING
		NAV_STATE.ATTACKING:
			# stay attacking until timer is up
			if attack_timer.is_stopped():
				# TODO we could do a cooldown instead of going to
				# moving -> attack instantly.
				return NAV_STATE.MOVING
			else:
				return NAV_STATE.ATTACKING
		NAV_STATE.WAITING:
			# TODO wait for target
			if player_pos.distance_to(agent_pos) < AGGRO_RANGE:
				return NAV_STATE.MOVING
			return NAV_STATE.WAITING
			
	return NAV_STATE.MOVING
	
	
func _process(delta):
	# TODO when within distance begin attack sequence
	nav_state = update_navigation_state()

func _physics_process(delta):
	
	if nav_state == NAV_STATE.MOVING:
		look_at(player.global_position)
	if navigation_agent.is_navigation_finished():
		return

	var current_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()

	velocity = current_position.direction_to(next_path_position) * MOVE_SPEED;
	velocity.y = 0.0;
	move_and_slide()
