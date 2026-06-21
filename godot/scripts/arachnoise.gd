extends Node2D

const Mozzie = preload("res://scenes/prey/mozzie.tscn")

@onready var automator: AnimationPlayer = $Automator
@onready var game: Parallax2D = %Game
var initial_buzz = false
# Okay, we're vaguely setup. 

# We're going to make use of our 'anchor' lines, 1-13,
# which are representative of the following -

# 1 - C > C Dm Em F G Am B
# 2 - G > G Am Bm C D Em F#
# 3 - D > D Em F#m G A Bm C#
# 4 - A > A Bm C# D E F#m G#
# 5 - E > E F#m G#m A B C#m D#
# 6 - B > B C#m D#m E F# G#m A#
# 7 - F# > F# G#m A#m B C# D#m E#
# 8 - Gb > Gb Abm Bbm Cb Db Ebm F
# 9 - Db > Db Ebm Fm Gb Ab Bbm C
#10 - Ab > Ab Bbm Cm Db Eb Fm G
#11 - Eb > Eb Fm Gm Ab Bb Cm D
#12 - Bb > Bb Cm Dm Eb F Gm A
#13 - F > F Gm Am Bb C Dm E


# This gives us a sequence to follow for each 'prey'

func _ready() -> void:
	$Automator.play("fade_in")
	$Ambience.finished.connect(func(): $Ambience.play())

func _buzz_spidey():
	if $Game/Prey/Container.get_child_count() == 0:
		var prey = _new_prey()
		$Game/Prey/Container.add_child(prey)
		$Game/Prey/Automator.play_with_capture("lurk", 1.5)
	else:
		print("uhm?")

func _new_prey() -> CharacterBody2D: 
	var prey: = Mozzie.instantiate()
	return prey
	
func _drop_prey():
	for i in $Game/Prey/Container.get_child_count():
		$Game/Prey/Container.get_child(i).queue_free()
		
func _on_loitering_state_entered() -> void:
	# Random timer from 4-7s, mosquito 'appears' - root note chosen, gradient radial blur with note
	# color and pulse animation near random screen edge. 
	if $Game/Prey/Container.get_child_count() > 0:
		$Game/Prey/Automator.play_with_capture("flee", 1.5)
		get_tree().create_timer(2.5).timeout.connect(_drop_prey)
	
	var wait_length = randi_range(4,7) * (2 if not initial_buzz else 4)
	get_tree().create_timer(wait_length).timeout.connect(_buzz_spidey)

func _on_enticing_state_entered() -> void:
	#$BuzzTrack.play()
	pass

func _on_trapping_state_entered() -> void:
	pass # Replace with function body.

func _on_ensnared_state_entered() -> void:
	pass # Replace with function body.

func _on_phrase_1_state_entered() -> void:
	pass # Replace with function body.

func _on_phrase_2_state_entered() -> void:
	pass # Replace with function body.

func _on_phrase_3_state_entered() -> void:
	pass # Replace with function body.

func _on_success_state_entered() -> void:
	pass # Replace with function body.

func _on_prey_startled_taken() -> void:
	pass # Replace with function body.

func _on__plucked(key: String, note: int) -> void:
	# Actually check harmony/discord
	$State.send_event("StartlePrey")
