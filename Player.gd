extends KinematicBody2D

# constant physics variables
const WALK_FORCE = 600

const WALK_MAX_SPEED = 400
const AIR_MAX_SPEED = 200

const GROUND_STOP_FORCE = 1300
const AIR_STOP_FORCE = 200

const JUMP_SPEED = 500

const WALKING_DEADZONE = 0.2

# changable physics variables
var max_speed := WALK_MAX_SPEED
var stop_force := GROUND_STOP_FORCE
var gravity : int = 800

# input variables
# specifically for horizontal movement
var horizontal_speed : float
var is_jumping : bool

# ----------------------------------------
# turn into packets, game state related
var velocity = Vector2()
var is_grounded : bool = false
# ----------------------------------------

func _physics_process(delta : float):
	check_inputs()
	handle_physics(delta)
	handle_jump()
	check_states()
	send_packets()

func check_inputs():
	# Horizontal movement code. First, get the player's input.
	horizontal_speed = WALK_FORCE * (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	
	# Check for jumping. is_on_floor() must be called after movement code.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		is_jumping = true
	# will probably remove thing and replace with a jumpsquat or something
	else:
		is_jumping = false

func handle_physics(delta : float):
	# Slow down the player if they're not trying to move.
	if abs(horizontal_speed) < WALK_FORCE * WALKING_DEADZONE:
		# The velocity, slowed down a bit, and then reassigned.
		velocity.x = move_toward(velocity.x, 0, stop_force * delta)
	else:
		velocity.x += horizontal_speed  * delta
	# Clamp to the maximum horizontal movement speed.
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	# Vertical movement code. Apply gravity.
	velocity.y += gravity * delta

	# The second parameter of "move_and_slide" is the normal pointing up.
	# In the case of a 2D platformer, in Godot, upward is negative y, which translates to -1 as a normal.
	move_and_slide(velocity, Vector2(0, -1))

func handle_jump():
	# Check for jumping. is_on_floor() must be called after movement code.
	if is_jumping:
		velocity.y = -JUMP_SPEED

func check_states():
	# set different speeds in the air and ground
	if is_on_floor():
		max_speed = WALK_MAX_SPEED
		stop_force = GROUND_STOP_FORCE
		
		# unless we're jumping, set velocity to 0 so that when we fall off, we drop off super fast
		if !is_jumping:
			velocity.y = 0
	else:
		max_speed = AIR_MAX_SPEED
		stop_force = AIR_STOP_FORCE
	
	is_grounded = is_on_floor()

func send_packets():
	# We want to send three things all bundled together into one packet
	# Right now, we're going to print all of this instead, like we're sending a packet
	# make an array of what we wanna send
	# for the sake of simplicity, im putting the booleans in a vector 2
	var send_array : Array = [self.position, velocity, Vector2(is_grounded, 0)]
	# then turn the array into a pool byte array
	var packet_send_array : PoolVector2Array = PoolVector2Array(send_array)
	
	deserialize_packets(packet_send_array)

func deserialize_packets(recieve_array : PoolVector2Array):
	var remote_position : Vector2 = recieve_array[0]
	var remote_velocity : Vector2 = recieve_array[1]
	var remote_boolean_vector : Vector2 = recieve_array[2]
	var remote_is_grounded : bool = bool(remote_boolean_vector[0])
