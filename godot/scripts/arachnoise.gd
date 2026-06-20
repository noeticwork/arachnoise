extends Node2D

@onready var automator: AnimationPlayer = $Automator
@onready var game: Parallax2D = %Game

# Okay, we're vaguely setup. 

# We're going to make use of our 'anchor' lines, 1-12,
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



# This gives us a sequence to follow for each 'prey' - who will land
# on some point in this space

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Automator.play("fade_in")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
