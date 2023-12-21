extends CharacterBody3D

enum NAV_STATE {MOVING, ATTACKING, WAITING}
enum ATTACK_STATE {READY, WINDUP, ATTACK, COOLDOWN}

@export var ATTACK_CANCEL_RANGE: float = 3.0
@export var ATTACK_BEGIN_RANGE: float = 2.0
@export var MOVE_SPEED: float = 8.0
@export var AGGRO_RANGE: float = 20.0
@export var ATTACK_DURATION: float = 0.5;
@export var WINDUP_DURATION: float = 0.5;
@export var COOLDOWN_DURATION: float = 0.5;

var navmap_ready = false
var nav_state = NAV_STATE.WAITING
var attack_state = ATTACK_STATE.READY
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

func update_attack_state() -> ATTACK_STATE:
	match attack_state:
		ATTACK_STATE.READY:
			attack_timer.start(WINDUP_DURATION)
			return ATTACK_STATE.WINDUP
		ATTACK_STATE.WINDUP:
			if attack_timer.is_stopped():
				attack_timer.start(ATTACK_DURATION)
				return ATTACK_STATE.ATTACK
			else:
				return ATTACK_STATE.WINDUP
			pass
		ATTACK_STATE.ATTACK:
			if attack_timer.is_stopped():
				attack_timer.start(COOLDOWN_DURATION)
				return ATTACK_STATE.COOLDOWN
			else:
				return ATTACK_STATE.ATTACK
			pass
		ATTACK_STATE.COOLDOWN:
			if attack_timer.is_stopped():
				return ATTACK_STATE.READY
			else:
				return ATTACK_STATE.COOLDOWN
	return ATTACK_STATE.READY

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
					return NAV_STATE.ATTACKING
			else:
				var target_pos = navigation_agent.target_position
				if target_pos.distance_to(player_pos) > ATTACK_BEGIN_RANGE:
					# Target position would be outside of begin range, find
					# a new position
					navigation_agent.set_target_position(player_pos)
			return NAV_STATE.MOVING
		NAV_STATE.ATTACKING:
			attack_state = update_attack_state()
			if attack_state == ATTACK_STATE.COOLDOWN or attack_state == ATTACK_STATE.READY:
				# Attack is finished
				return NAV_STATE.MOVING
			else:
				return NAV_STATE.ATTACKING
		NAV_STATE.WAITING:
			if player_pos.distance_to(agent_pos) < AGGRO_RANGE:
				return NAV_STATE.MOVING
			return NAV_STATE.WAITING
			
	return NAV_STATE.MOVING
	
	
func _process(delta):
	# TODO when within distance begin attack sequence
	nav_state = update_navigation_state()

var temp = false
func _physics_process(delta):
	
	# TODO face player (rotate about y only)
	if attack_state == ATTACK_STATE.ATTACK:
		if not temp:
			$shoulder/left_arm/MeshInstance3D.translate(Vector3(1.0, 0.0, 0.0))
			$shoulder/left_arm/MeshInstance3D.rotate(Vector3(0,0,1), PI/2)
			$shoulder/right_arm/MeshInstance3D.translate(Vector3(-1.0, 0.0, 0.0))
			$shoulder/right_arm/MeshInstance3D.rotate(Vector3(0,0,1), -PI/2)
			temp = true
		$shoulder.rotate_y(0.2)
	else:
		$shoulder.set_identity()
		$shoulder/left_arm/MeshInstance3D.set_identity()
		$shoulder/right_arm/MeshInstance3D.set_identity()

		temp = false
	if navigation_agent.is_navigation_finished():
		return

	var current_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()

	velocity = current_position.direction_to(next_path_position) * MOVE_SPEED;
	velocity.y = 0.0;
	move_and_slide()
