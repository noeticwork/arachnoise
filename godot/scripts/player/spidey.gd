extends CharacterBody2D
class_name spider

@export var move_speed: float = 100
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@export var state_chart: StateChart

var input_direction: Vector2 = Vector2.ZERO
var current_state: String = ""


func _physics_process(_delta):
	input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	
	velocity = input_direction * move_speed
	
	if not velocity.is_zero_approx():
		if abs(input_direction.x) > 0.4:
			if input_direction.x > 0:
				sprite.flip_h = true
			elif input_direction.x < 0:
				sprite.flip_h = false
				
		if abs(input_direction.y) > 0.4:
			if input_direction.y > 0:
				sprite.flip_v = false
			elif input_direction.y < 0:
				sprite.flip_v = true
			
	move_and_slide()
	pick_new_state()
	
func flip_sprite():
	if abs(input_direction.x) > 0.7:
		scale.x = -1 if input_direction.x < 0 else 1

func pick_new_state():
	var new_state = "walk" if input_direction != Vector2.ZERO else "idle"
	if new_state != current_state:
		current_state = new_state
		state_machine.travel(new_state)
		
