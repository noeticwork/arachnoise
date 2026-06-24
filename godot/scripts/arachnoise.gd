extends Node2D

const Mozzie = preload("res://scenes/prey/prey.tscn")

@onready var automator: AnimationPlayer = $Automator
@onready var game: Parallax2D = %Game
var current_prey: Prey
var current_target_note: String
var current_snare_key: String
var initial_buzz = false

const notes = [
	"C",
	"G",
	"D",
	"A",
	"E",
	"B",
	"Db",
	"Ab",
	"Eb",
	"Bb",
	"F",
	# Advanced!
	"F#"
	#"Gb"
];

# Okay, we're vaguely setup. 
#var bug_sting = "C6
	#F6
	#F5
	#Bb6
	#Bb5
	#Eb6
	#Eb5
	#Gb1
	#"
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
	MidiInputManager.note_on.connect(_on_note_on)
	MidiInputManager.note_off.connect(_on_note_off)
	MidiInputManager.chord_played.connect(_on_chord_played)
	MidiInputManager.pad_hit.connect(_on_pad_hit)
	MidiInputManager.pitch_bend_changed.connect(_on_pitch_bend)
	MidiInputManager.mod_changed.connect(_on_mod)

func _on_note_on(pitch: int, velocity: int, channel: int) -> void:
	_printt("note_on  pitch=%d  vel=%d  ch=%d" % [pitch, velocity, channel])

func _on_note_off(pitch: int, channel: int) -> void:
	_printt("note_off pitch=%d  ch=%d" % [pitch, channel])

func _on_chord_played(notes: Array[int], root: int, quality: String, chord_name: String) -> void:
	_printt("chord: %s  (root=%d, quality=%s, notes=%s)" % [chord_name, root, quality, notes])
	# → light up spiderweb, update tutor window, score player, etc.

func _on_pad_hit(pad_index: int, velocity: int) -> void:
	_printt("pad %d  vel=%d" % [pad_index, velocity])

func _on_pitch_bend(value: float) -> void:
	_printt("bend %.3f" % value)   # -1.0 left, +1.0 right

func _on_mod(value: float) -> void:
	_printt("mod  %.3f" % value)   # 0.0 .. 1.0
	
	
func _printt(args) -> void:
	print(args)
	$PhantomCamera2D/CanvasLayer/RichTextLabel.text += "\r\n" + args

func _input(event: InputEvent) -> void:
	if event.is_action("refresh_random"):
		get_tree().reload_current_scene()

func _new_prey() -> Prey: 
	var prey: = Mozzie.instantiate()
	return prey
	
func _drop_prey():
	if current_prey:
		current_prey.queue_free()
	for i in %PreyContainer.get_child_count():
		%PreyContainer.get_child(i).queue_free()
		
func _on_loitering_state_entered() -> void:
	print("Loitering ...")
	if not initial_buzz:
		%PreyAutomator.play_with_capture("RESET", 1)
		current_target_note = ""
		%PreyAutomator.play("lurk")
	if current_prey: current_prey.state.send_event("Calmed")

func _on_enticing_state_entered() -> void:
	print("Enticing ...")
	current_target_note = random_chime()
	current_prey.state.send_event("BuzzSpidey")

func _on_trapping_state_entered() -> void:
	print("Trapping ...")
	%PreyAutomator.play_with_capture("RESET", 1)
	current_prey.state.send_event("HarmonizeEnticement")
	var target_location = null
	for i in $Game/Web/Keylines.get_child_count():
		var keyline: KeyLine = $Game/Web/Keylines.get_child(i) as KeyLine
		if keyline:
			if keyline.key == current_target_note:
				target_location = keyline.vii.global_position
	if target_location:
		current_prey.goto(target_location)
		current_prey.prey_snared.connect(func():
			$State.send_event("PreySnared")
			
		)
	else:
		print("Uhoh")

func _on_ensnared_state_entered() -> void:
	print("Ensnared ...")
	for i in $Game/Web/Keylines.get_child_count():
		var child = $Game/Web/Keylines.get_child(i) as KeyLine
		if child and child.key == current_target_note:
			$Game/Web/Keylines.get_child(i).wiggle()
	$Pads.stream = load("res://assets/audio/Pads/%smaj.wav" % current_target_note)
	$Pads.play()
	$Pads.finished.connect(func(): $Pads.play())

	current_snare_key = current_target_note
	current_target_note = ""

func random_chime() -> String:
	return notes[randi_range(1,12)-1]
	
func play_current_entice_chime() -> void:
	if current_target_note:
		ChimePlayer.play("celeste_%s" % current_target_note)
		_printt("... played %s" % current_target_note)
	
func _on_phrase_1_state_entered() -> void:
	pass 

func _on_phrase_2_state_entered() -> void:
	pass
	
func _on_phrase_3_state_entered() -> void:
	pass

func _on_success_state_entered() -> void:
	pass


func _keep_lurking() -> void:
	%PreyAutomator.play_with_capture("lurk", 1.0)

func _on__plucked(key: String, note: int) -> void:
	print(key, note)
	if current_prey and current_target_note:
		if key != current_target_note:
			$State.send_event("StartlePrey")
		else:
			$State.send_event("KeyEchoed")
	if $State/CompoundState/Ensnared.active:
		if key == current_snare_key:
			$State.send_event("PreyEscapes")
			current_prey.state.send_event("EscapingWeb")

func _on_fleeing_state_entered() -> void:
	if current_prey:
		print("Startled, fleeing!")
		current_prey.state.send_event("Startled")
		get_tree().create_timer(4).timeout.connect(func(): 
			print("Calming ...")
			$State.send_event("Calmed")
	)


func _on_spawning_state_entered() -> void:
	current_prey = _new_prey()
	%PreyContainer.add_child(current_prey)
	var wait_length = randi_range(4,7) * (2 if not initial_buzz else 4)
	get_tree().create_timer(wait_length).timeout.connect(func():
		%PreyAutomator.play_with_capture("lurk", 1.5)
		$State.send_event("Ready")
	)
