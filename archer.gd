extends CharacterBody3D

enum NAV_STATE {MOVING, ATTACKING, WAITING}
enum ATTACK_STATE {READY, WINDUP, ATTACK, COOLDOWN}

@export var ATTACK_CANCEL_RANGE: float = 3.0
@export var ATTACK_BEGIN_RANGE: float = 2.0
@export var MOVE_SPEED: float = 8.0
@export var AGGRO_RANGE: float = 20.0
@export var ATTACK_DURATION: float = 1.0;
@export var WINDUP_DURATION: float = 0.2;
@export var COOLDOWN_DURATION: float = 0.5;
@export var DESPAWN_TIMER_SECONDS: float = 5.0;

var navmap_ready = false
var nav_state = NAV_STATE.WAITING
var attack_state = ATTACK_STATE.READY
var player = null
var despawn_timer_started = false

@onready var navigation_agent = $navigation_point/NavigationAgent3D

@onready var attack_timer = $attack_timer
@onready var despawn_timer = $despawn

@onready var left_arm_mesh = $shoulder/left_arm/MeshInstance3D
@onready var right_arm_mesh = $shoulder/right_arm/MeshInstance3D
@onready var left_emitter = $shoulder/left_arm/GPUParticles3D
@onready var right_emitter = $shoulder/right_arm/GPUParticles3D
@onready var shoulder = $shoulder

# p in [0,1]
# s in [0,1)
func sigmoid(t: float, p: float, s: float) -> float:
	var c = 2 / (1 - s) - 1
	if t <= p:
		return pow(t, c) / (pow(p, c - 1))
	else:
		return 1 - (pow(1 - t, c) / pow(1 - p, c - 1))

# shabby approx tangent to even sigmoid
func der_sigmoid(t: float) -> float:
	return clampf(-pow(2.5 * t - 1.25, 2) + 1, 0, 1)

func _ready():
	call_deferred("deferred")
	player = get_tree().current_scene.get_node("Player")
	navigation_agent.target_desired_distance = ATTACK_BEGIN_RANGE;
	navigation_agent.path_desired_distance = ATTACK_BEGIN_RANGE;
	
func spawn_at(start_position: Vector3):
	position = start_position
	

func deferred():
	await get_tree().physics_frame
	navmap_ready = true

func update_attack_state() -> ATTACK_STATE:
	if health <= 0:
		return ATTACK_STATE.READY
	match attack_state:
		ATTACK_STATE.READY:
			attack_timer.start(WINDUP_DURATION)
			return ATTACK_STATE.WINDUP
		ATTACK_STATE.WINDUP:
			# TODO could implement attack cancellation during windup
			# if the target moves out of range, transition
			# to ready in that case.
			if attack_timer.is_stopped():
				attack_timer.start(ATTACK_DURATION)
				left_emitter.set_emitting(true)
				right_emitter.set_emitting(true)
				left_emitter.set_amount_ratio(0)
				right_emitter.set_amount_ratio(0)
				return ATTACK_STATE.ATTACK
			else:
				var t = 1 - (attack_timer.time_left / WINDUP_DURATION)
				left_arm_mesh.set_identity()
				left_arm_mesh.translate(Vector3(1.0, 0.0, 0.0) * t)
				left_arm_mesh.rotate_z(t * PI/2)
				right_arm_mesh.set_identity()
				right_arm_mesh.translate(Vector3(-1.0, 0.0, 0.0) * t)
				right_arm_mesh.rotate_z(t * -PI/2)
				return ATTACK_STATE.WINDUP
			pass
		ATTACK_STATE.ATTACK:
			
			if attack_timer.is_stopped():
				attack_timer.start(COOLDOWN_DURATION)
				left_emitter.set_emitting(false)
				right_emitter.set_emitting(false)
				return ATTACK_STATE.COOLDOWN
			else:
				shoulder.set_rotation
				shoulder.set_identity()
				var t = 1 - (attack_timer.time_left / ATTACK_DURATION)
				shoulder.rotate_y(sigmoid(t, 0.5, 0.5) * TAU)
				$shoulder/left_arm/GPUParticles3D.set_amount_ratio(der_sigmoid(t))
				$shoulder/right_arm/GPUParticles3D.set_amount_ratio(der_sigmoid(t))
				return ATTACK_STATE.ATTACK
			pass
		ATTACK_STATE.COOLDOWN:
			# TODO animate the winddown by translating back to center
			if attack_timer.is_stopped():
				shoulder.set_identity()
				left_arm_mesh.set_identity()
				right_arm_mesh.set_identity()
				return ATTACK_STATE.READY
			else:
				var t = (attack_timer.time_left / COOLDOWN_DURATION)
				left_arm_mesh.set_identity()
				left_arm_mesh.translate(Vector3(1.0, 0.0, 0.0) * t)
				left_arm_mesh.rotate_z(t * PI/2)
				right_arm_mesh.set_identity()
				right_arm_mesh.translate(Vector3(-1.0, 0.0, 0.0) * t)
				right_arm_mesh.rotate_z(t * -PI/2)
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
			if attack_state == ATTACK_STATE.READY:
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
	nav_state = update_navigation_state()
	# TODO could bring update_attack_state() to this level
	# to allow cooldown animation to be updated outside of the attack
	# navigation state.
	# Also this allows for winding up while moving to the player.

func _physics_process(delta):
	
	if health <= 0 and not despawn_timer_started:
		despawn_timer.start(DESPAWN_TIMER_SECONDS)
		despawn_timer_started = true
		return
	
	if despawn_timer_started:
		return	
	
	if nav_state != NAV_STATE.WAITING:
		var player_pos = player.global_position
		player_pos.y = global_position.y
		look_at(player_pos)

	if navigation_agent.is_navigation_finished():
		return

	var current_position = global_position
	var next_path_position = navigation_agent.get_next_path_position()

	velocity = current_position.direction_to(next_path_position) * MOVE_SPEED;
	velocity.y = 0.0;
	move_and_slide()
	
# ------- Damage -------
@export var mob_maxhealth = 100
var health = mob_maxhealth

func take_damage(amount: int):
	health -= amount	
	$Healthbar3D.update(health, mob_maxhealth)
	
	if health <= 0:
		$torso.freeze = false
		$shoulder/left_arm.freeze = false
		$shoulder/right_arm.freeze = false
		$head.freeze = false
		#queue_free()


func _on_despawn_timeout():
	# TODO: Add death + fade animation
	queue_free()
	#pass # Replace with function body.
