extends CharacterBody2D
class_name Prey

@export var state: StateChart
@export var nav_agent: NavigationAgent2D

@export var movement_speed: float = 400.0

signal prey_snared


func _on_lurking_state_entered() -> void:
	$Automator.play("lurk")
	
func goto(location: Vector2) -> void:
	nav_agent.target_position = location

func _on_fleeing_state_entered() -> void:
	$Automator.play("flee")

func _ready() -> void:
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))

func set_movement_target(movement_target: Vector2):
	nav_agent.set_target_position(movement_target)

func _physics_process(delta):
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		return
	if nav_agent.is_navigation_finished():
		return

	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movement_speed
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()


func _on_nav_agent_navigation_finished() -> void:
	if $State/CompoundState/Stuck/Sticking.active:
		$State.send_event("GotStuck")


func _on_struggling_state_entered() -> void:
	$Automator.play("trapped")
	emit_signal("prey_snared")
