extends Node2D

@onready var automator: AnimationPlayer = $Automator
@onready var game: Parallax2D = %Game

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Automator.play("fade_in")
	
func _input(event: InputEvent) -> void:
	pass
	#if event.is_action("refresh_random"):
		#%Pads.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_loitering_state_entered() -> void:
	# Random timer from 4-7s, mosquito 'appears' - root note chosen, gradient radial blur with note
	# color and pulse animation near random screen edge. 
	pass


func _on_enticing_state_entered() -> void:
	pass # Replace with function body.


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
