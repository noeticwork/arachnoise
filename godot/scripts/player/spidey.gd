extends CharacterBody2D
class_name Spidey

@export var move_speed: float = 120
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@export var state_chart: StateChart
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

var input_direction: Vector2 = Vector2.ZERO
var midi_direction: Vector2 = Vector2.ZERO
var current_state: String = ""
var mode_switching: bool = false

func pick_new_state():
	var new_state = "walk" if input_direction != Vector2.ZERO else "idle"
	if new_state != current_state:
		current_state = new_state
		state_machine.travel(new_state)

func _on_web_state_physics_processing(delta: float) -> void:
	var keyboard_dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	# Combine keyboard and MIDI — keyboard is binary 0/1, MIDI carries magnitude
	# Prefer whichever is non-zero; if both, sum and clamp length to 1
	var combined := keyboard_dir + midi_direction
	if combined.length() > 1.0:
		combined = combined.normalized()
	input_direction = combined

	velocity = input_direction * move_speed

	if not velocity.is_zero_approx():
		$AnimatedSprite2D.play("walk")
		if abs(input_direction.x) > 0.3:
			$AnimatedSprite2D.flip_h = input_direction.x > 0
		if abs(input_direction.y) > 0.3:
			$AnimatedSprite2D.flip_v = input_direction.y >= 0
	else:
		$AnimatedSprite2D.play("idle")

	move_and_slide()
	pick_new_state()


@export var README: String = "IMPORTANT: MAKE SURE TO ASSIGN 'left' 'right' 'jump' 'dash' 'up' 'down' in the project settings input map."

@export_category("Necesary Child Nodes")
@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D

@export_category("L/R Movement")
@export_range(50, 500) var maxSpeed: float = 200.0
@export_range(0, 4) var timeToReachMaxSpeed: float = 0.2
@export_range(0, 4) var timeToReachZeroSpeed: float = 0.2
@export var directionalSnap: bool = false
@export var runningModifier: bool = false

@export_category("Jumping and Gravity")
@export_range(0, 20) var jumpHeight: float = 2.0
@export_range(0, 4) var jumps: int = 1
@export_range(0, 100) var gravityScale: float = 20.0
@export_range(0, 1000) var terminalVelocity: float = 500.0
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
@export var shortHopAkaVariableJumpHeight: bool = true
@export_range(0, 0.5) var coyoteTime: float = 0.2
@export_range(0, 0.5) var jumpBuffering: float = 0.2

@export_category("Wall Jumping")
@export var wallJump: bool = false
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
@export_range(0, 90) var wallKickAngle: float = 60.0
@export_range(1, 20) var wallSliding: float = 1.0
@export var wallLatching: bool = false
@export var wallLatchingModifer: bool = false

@export_category("Dashing")
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dashType: int
@export_range(0, 10) var dashes: int = 1
@export var dashCancel: bool = true
@export_range(1.5, 4) var dashLength: float = 2.5

@export_category("Corner Cutting/Jump Correct")
@export var cornerCutting: bool = false
@export_range(1, 5) var correctionAmount: float = 1.5
@export var leftRaycast: RayCast2D
@export var middleRaycast: RayCast2D
@export var rightRaycast: RayCast2D

@export_category("Down Input")
@export var crouch: bool = false
@export var canRoll: bool
@export_range(1.25, 2) var rollLength: float = 2
@export var groundPound: bool
@export_range(0.05, 0.75) var groundPoundPause: float = 0.25
@export var upToCancel: bool = false

@export_category("Animations (Check Box if has animation)")
@export var run: bool
@export var jump: bool
@export var idle: bool
@export var walk: bool
@export var slide: bool
@export var latch: bool
@export var falling: bool
@export var crouch_idle: bool
@export var crouch_walk: bool
@export var roll: bool

var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 500.0
var jumpCount: int
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var dashMagnitude: float
var gravityActive: bool = true
var dashing: bool = false
var dashCount: int
var rolling: bool = false

var twoWayDashHorizontal
var twoWayDashVertical
var eightWayDash

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true)

var gdelta: float = 1
var dset = false

var colliderScaleLockY
var colliderPosLockY

var latched
var wasLatched
var crouching
var groundPounding

var anim
var col
var animScaleLock: Vector2

var upHold
var downHold
var leftHold
var leftTap
var leftRelease
var rightHold
var rightTap
var rightRelease
var jumpTap
var jumpRelease
var runHold
var latchHold
var dashTap
var rollTap
var downTap
var twirlTap

func _ready():
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	MidiMovementController.movement_vector_changed.connect(_on_move)
	MidiMovementController.mode_changed.connect(_on_mode_change)

	MidiMovementController.build_angles(90.0, -30.0)
	MidiMovementController.print_angle_table()
	MidiMovementController.toggle_linear_mode()
	MidiInputManager.pad_hit.connect(func(idx, _vel):
		if idx == 1: MidiMovementController.toggle_linear_mode())
	_updateData()

func _on_mode_change(mode: int):
	print("Changing modes %s" % mode)
	
func _on_move(vec: Vector2):
	midi_direction = vec * 2

func _updateData():
	acceleration = maxSpeed / timeToReachMaxSpeed
	deceleration = -maxSpeed / timeToReachZeroSpeed

	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	jumpCount = jumps

	dashMagnitude = maxSpeed * dashLength
	dashCount = dashes

	maxSpeedLock = maxSpeed

	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y

	if timeToReachMaxSpeed == 0:
		instantAccel = true
		timeToReachMaxSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantAccel = false
	else:
		instantAccel = false

	if timeToReachZeroSpeed == 0:
		instantStop = true
		timeToReachZeroSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantStop = false
	else:
		instantStop = false

	if jumps > 1:
		jumpBuffering = 0
		coyoteTime = 0

	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)

	if directionalSnap:
		instantAccel = true
		instantStop = true

	twoWayDashHorizontal = false
	twoWayDashVertical = false
	eightWayDash = false
	if dashType == 1:
		twoWayDashHorizontal = true
	elif dashType == 2:
		twoWayDashVertical = true
	elif dashType == 3:
		twoWayDashHorizontal = true
		twoWayDashVertical = true
	elif dashType == 4:
		eightWayDash = true


func _on_jumping_state_processing(_delta: float) -> void:
	if is_on_wall() and !_is_on_floor() and latch and wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
		latched = true
	else:
		latched = false
		wasLatched = true
		_setLatch(0.2, false)

	if rightHold and !latched:
		anim.scale.x = animScaleLock.x * -1
	if leftHold and !latched:
		anim.scale.x = animScaleLock.x

	if run and idle and !dashing and !crouching:
		if abs(velocity.x) > 0.1 and _is_on_floor() and !is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			anim.play("run")
		elif abs(velocity.x) < 0.1 and _is_on_floor():
			anim.speed_scale = 1
			anim.play("idle")
	elif run and idle and walk and !dashing and !crouching:
		if abs(velocity.x) > 0.1 and _is_on_floor() and !is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			anim.play("walk" if abs(velocity.x) < maxSpeedLock else "run")
		elif abs(velocity.x) < 0.1 and _is_on_floor():
			anim.speed_scale = 1
			anim.play("idle")

	if velocity.y < 0 and jump and !dashing:
		anim.speed_scale = 1
		anim.play("jump")
		$ShadowPlayer.play_with_capture("jump_%d" % (jumps - jumpCount), 0.2)

	if velocity.y > 40 and falling and !dashing and !crouching:
		anim.speed_scale = 1
		anim.play("falling")
		$AnimatedSprite2D.flip_v = false
		$ShadowPlayer.play_with_capture("jump_1", 0.2)
		if Input.is_action_just_pressed("jump") or Input.is_action_just_released("jump"):
			$Gestalt.send_event("WebMode")

	if latch and slide:
		if latched and !wasLatched:
			anim.speed_scale = 1
			anim.play("latch")
		if is_on_wall() and velocity.y > 0 and slide and anim.animation != "slide" and wallSliding != 1:
			anim.speed_scale = 1
			anim.play("slide")
		if dashing:
			anim.speed_scale = 1
			anim.play("dash")
		if crouching and !rolling:
			anim.speed_scale = 1
			anim.play("crouch_walk" if abs(velocity.x) > 10 else "crouch_idle")
		if rollTap and canRoll and roll:
			anim.speed_scale = 1
			anim.play("roll")


func _on_jumping_state_physics_processing(delta: float) -> void:
	if !dset:
		gdelta = delta
		dset = true

	leftHold = Input.is_action_pressed("ui_left")
	rightHold = Input.is_action_pressed("ui_right")
	upHold = Input.is_action_pressed("ui_up")
	downHold = Input.is_action_pressed("ui_down")
	leftTap = Input.is_action_just_pressed("ui_left")
	rightTap = Input.is_action_just_pressed("ui_right")
	leftRelease = Input.is_action_just_released("ui_left")
	rightRelease = Input.is_action_just_released("ui_right")
	jumpTap = mode_switching or Input.is_action_just_pressed("jump")
	jumpRelease = Input.is_action_just_released("jump")
	runHold = Input.is_action_pressed("run")
	latchHold = Input.is_action_pressed("latch")
	dashTap = Input.is_action_just_pressed("dash")
	rollTap = Input.is_action_just_pressed("roll")
	downTap = Input.is_action_just_pressed("ui_down")
	twirlTap = Input.is_action_just_pressed("twirl")

	if Input.is_action_just_pressed("web_mode"):
		$Gestalt.send_event("WebMode")
		return

	# Merge MIDI horizontal input with keyboard
	if midi_direction.x > 0.3:
		rightHold = true
	elif midi_direction.x < -0.3:
		leftHold = true

	if rightHold and leftHold and movementInputMonitoring:
		if !instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = -0.1
	elif rightHold and movementInputMonitoring.x:
		if velocity.x > maxSpeed or instantAccel:
			velocity.x = maxSpeed
		else:
			velocity.x += acceleration * delta
		if velocity.x < 0:
			if !instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = -0.1
	elif leftHold and movementInputMonitoring.y:
		if velocity.x < -maxSpeed or instantAccel:
			velocity.x = -maxSpeed
		else:
			velocity.x -= acceleration * delta
		if velocity.x > 0:
			if !instantStop:
				_decelerate(delta, false)
			else:
				velocity.x = 0.1

	if velocity.x > 0:
		wasMovingR = true
	elif velocity.x < 0:
		wasMovingR = false

	if rightTap:
		wasPressingR = true
	if leftTap:
		wasPressingR = false

	if runningModifier and !runHold:
		maxSpeed = maxSpeedLock / 2
	elif _is_on_floor():
		maxSpeed = maxSpeedLock

	if !(leftHold or rightHold):
		if !instantStop:
			_decelerate(delta, false)
		else:
			velocity.x = 0

	if crouch:
		if downHold and _is_on_floor():
			crouching = true
		elif !downHold and ((runHold and runningModifier) or !runningModifier) and !rolling:
			crouching = false

	if !_is_on_floor():
		crouching = false

	if crouching:
		maxSpeed = maxSpeedLock / 2
		col.scale.y = colliderScaleLockY / 2
		col.position.y = colliderPosLockY + (8 * colliderScaleLockY)
	else:
		maxSpeed = maxSpeedLock
		col.scale.y = colliderScaleLockY
		col.position.y = colliderPosLockY

	if canRoll and _is_on_floor() and rollTap and crouching:
		_rollingTime(0.75)
		if wasPressingR and !upHold:
			velocity.y = 0
			velocity.x = maxSpeedLock * rollLength
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(rollLength * 0.0625)
		elif !upHold:
			velocity.y = 0
			velocity.x = -maxSpeedLock * rollLength
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(rollLength * 0.0625)

	if canRoll and rolling:
		pass

	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor
	else:
		appliedGravity = gravityScale

	if is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity / wallSliding
		if wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
			appliedGravity = 0
			if velocity.y < 0:
				velocity.y += 50
			if velocity.y > 0:
				velocity.y = 0
			if wallLatchingModifer and latchHold and movementInputMonitoring == Vector2(true, true):
				velocity.x = 0
		elif wallSliding != 1 and velocity.y > 0:
			appliedGravity = appliedGravity / wallSliding
	elif !is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity

	if gravityActive:
		if velocity.y < appliedTerminalVelocity:
			velocity.y += appliedGravity
		elif velocity.y > appliedTerminalVelocity:
			velocity.y = appliedTerminalVelocity

	if shortHopAkaVariableJumpHeight and jumpRelease and velocity.y < 0:
		velocity.y = velocity.y / 2

	if jumps == 1:
		if !_is_on_floor() and !is_on_wall():
			if coyoteTime > 0:
				coyoteActive = true
				_coyoteTime()

		if jumpTap and !is_on_wall():
			if coyoteActive:
				coyoteActive = false
				_jump()
			if jumpBuffering > 0:
				jumpWasPressed = true
				_bufferJump()
			elif jumpBuffering == 0 and coyoteTime == 0 and _is_on_floor():
				_jump()
		elif jumpTap and is_on_wall() and !_is_on_floor():
			if wallJump and !latched:
				_wallJump()
			elif wallJump and latched:
				_wallJump()
		elif jumpTap and _is_on_floor():
			_jump()

		if _is_on_floor():
			jumpCount = jumps
			coyoteActive = true
			if jumpWasPressed:
				_jump()

	elif jumps > 1:
		if _is_on_floor():
			jumpCount = jumps
		if jumpTap and jumpCount > 0 and !is_on_wall():
			velocity.y = -jumpMagnitude
			jumpCount = jumpCount - 1
			_endGroundPound()
		elif jumpTap and is_on_wall() and wallJump:
			_wallJump()

	if _is_on_floor():
		dashCount = dashes

	if eightWayDash and dashTap and dashCount > 0 and !rolling:
		# Use MIDI direction if active, else keyboard
		var dash_dir := midi_direction if midi_direction.length() > 0.1 else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var dTime := 0.0625 * dashLength
		_dashingTime(dTime)
		_pauseGravity(dTime)
		velocity = dashMagnitude * dash_dir
		dashCount += -1
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(dTime)

	if twoWayDashVertical and dashTap and dashCount > 0 and !rolling:
		var dTime := 0.0625 * dashLength
		if upHold and downHold:
			pass
		elif upHold:
			_dashingTime(dTime)
			_pauseGravity(dTime)
			velocity.x = 0
			velocity.y = -dashMagnitude
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
		elif downHold and dashCount > 0:
			_dashingTime(dTime)
			_pauseGravity(dTime)
			velocity.x = 0
			velocity.y = dashMagnitude
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)

	if twoWayDashHorizontal and dashTap and dashCount > 0 and !rolling:
		var dTime := 0.0625 * dashLength
		if wasPressingR and !(upHold or downHold):
			velocity.y = 0
			velocity.x = dashMagnitude
			_pauseGravity(dTime)
			_dashingTime(dTime)
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)
		elif !(upHold or downHold):
			velocity.y = 0
			velocity.x = -dashMagnitude
			_pauseGravity(dTime)
			_dashingTime(dTime)
			dashCount += -1
			movementInputMonitoring = Vector2(false, false)
			_inputPauseReset(dTime)

	if dashing and velocity.x > 0 and leftTap and dashCancel:
		velocity.x = 0
	if dashing and velocity.x < 0 and rightTap and dashCancel:
		velocity.x = 0

	if cornerCutting:
		if velocity.y < 0 and leftRaycast.is_colliding() and !rightRaycast.is_colliding() and !middleRaycast.is_colliding():
			position.x += correctionAmount
		if velocity.y < 0 and !leftRaycast.is_colliding() and rightRaycast.is_colliding() and !middleRaycast.is_colliding():
			position.x -= correctionAmount

	if groundPound and downTap and !_is_on_floor() and !is_on_wall():
		groundPounding = true
		gravityActive = false
		velocity.y = 0
		await get_tree().create_timer(groundPoundPause).timeout
		_groundPound()
	if _is_on_floor() and groundPounding:
		_endGroundPound()

	move_and_slide()
	mode_switching = false

	if upToCancel and upHold and groundPound:
		_endGroundPound()


func _bufferJump():
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false

func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	jumpCount += -1

func _jump():
	if jumpCount > 0:
		velocity.y = -jumpMagnitude
		jumpCount += -1
		jumpWasPressed = false
		#$AnimationPlayer.play("jump_shadow_%d" % (jumpCount + 1))

func _wallJump():
	var horizontalWallKick = abs(jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(jumpMagnitude * sin(wallKickAngle * (PI / 180)))
	velocity.y = -verticalWallKick
	var dir := -1 if wallLatchingModifer and latchHold else 1
	velocity.x = -horizontalWallKick * dir if wasMovingR else horizontalWallKick * dir
	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)

func _setLatch(delay, setBool):
	await get_tree().create_timer(delay).timeout
	wasLatched = setBool

func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)

func _decelerate(delta, vertical):
	if !vertical:
		if velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta

func _pauseGravity(time):
	gravityActive = false
	await get_tree().create_timer(time).timeout
	gravityActive = true

func _dashingTime(time):
	dashing = true
	await get_tree().create_timer(time).timeout
	dashing = false

func _rollingTime(time):
	rolling = true
	await get_tree().create_timer(time).timeout
	rolling = false

func _groundPound():
	appliedTerminalVelocity = terminalVelocity * 10
	velocity.y = jumpMagnitude * 2

func _endGroundPound():
	groundPounding = false
	appliedTerminalVelocity = terminalVelocity
	gravityActive = true

func _placeHolder():
	pass

func _is_on_floor() -> bool:
	return true if mode_switching else is_on_floor()

func _on_web_state_input(event: InputEvent) -> void:
	if event.is_action("jump"):
		mode_switching = true
		$Gestalt.send_event("Jump")

func _on_web_state_entered() -> void:
	$AnimationPlayer.play_with_capture("RESET")
	$ShadowPlayer.play_with_capture("RESET")
	#$ShadowNode/JumpShadow.hide()
	#$ShadowNode/Shadow.show()
	collision_layer = 1

func _on_jumping_state_entered() -> void:
	#$ShadowNode/JumpShadow.show()
	#$ShadowNode/Shadow.hide()
	$ShadowPlayer.play_with_capture("jump_1", 0.2)
	collision_layer = 2
