extends Node2D
@onready var line_texture: TextureRect = %LineTexture
@export var key: String

# We're going to make use of our 'anchor' lines, 1-12 (main scene),
# which are representative of the following keys, and progressions -

var keys = {
	"C":  ["C",  "Dm",  "Em",  "F",  "G",  "Am",  "Bdim"],
	"G":  ["G",  "Am",  "Bm",  "C",  "D",  "Em",  "F#dim"],
	"D":  ["D",  "Em",  "F#m", "G",  "A",  "Bm",  "C#dim"],
	"A":  ["A",  "Bm",  "C#m", "D",  "E",  "F#m", "G#dim"],
	"E":  ["E",  "F#m", "G#m", "A",  "B",  "C#m", "D#dim"],
	"B":  ["B",  "C#m", "D#m", "E",  "F#", "G#m", "A#dim"],
	"F#": ["F#", "G#m", "A#m", "B",  "C#", "D#m", "E#dim"],
	"Gb": ["Gb", "Abm", "Bbm", "Cb", "Db", "Ebm", "Fdim"],
	"Db": ["Db", "Ebm", "Fm",  "Gb", "Ab", "Bbm", "Cdim"],
	"Ab": ["Ab", "Bbm", "Cm",  "Db", "Eb", "Fm",  "Gdim"],
	"Eb": ["Eb", "Fm",  "Gm",  "Ab", "Bb", "Cm",  "Ddim"],
	"Bb": ["Bb", "Cm",  "Dm",  "Eb", "F",  "Gm",  "Adim"],
	"F":  ["F",  "Gm",  "Am",  "Bb", "C",  "Dm",  "Edim"]
}

var sharp_notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# Flat → sharp root conversion
var flat_to_sharp = {
	"Db": "C#",
	"Eb": "D#",
	"Gb": "F#",
	"Ab": "G#",
	"Bb": "A#",
	"Cb": "B",    # if needed
	"Fb": "E",    # if needed
	"E#": "F",    # just in case
	"B#": "C"     # just in case
}

# Returns res:// path to a chord file (defaults to CelesteChord instrument)
func get_chord_asset_path(chord: String, instrument: String = "CelesteChord") -> String:
	# 1. Extract root note
	var root: String
	if chord.ends_with("dim"):
		root = chord.trim_suffix("dim")
	elif chord.ends_with("m"):
		root = chord.trim_suffix("m")
	else:
		root = chord

	# 2. Normalise flat roots to sharp
	if root in flat_to_sharp:
		root = flat_to_sharp[root]

	# 3. Build filename and full path
	var filename = "/Chords/Chords " + instrument + root + ".wav"
	var full_path = "res://assets/audio/" + filename

	if FileAccess.file_exists(full_path):
		return full_path
	else:
		push_error("Missing chord file: " + full_path)
		return ""
		
func _sound_map(note: String) -> void:
	var path = get_chord_asset_path(note)
	if path.is_empty():
		return

	var audio_stream = load(path) as AudioStream
	if audio_stream:
		var player = %audio
		if player.playing:
			%automator.play("fade_out_pad")
			player.finished.connect(func(): _sound_map(note))

		player.stream = audio_stream
		player.play()

func _ready() -> void:
	
	_randomize()

func _randomize() -> void:
	line_texture.texture = load("res://assets/line%d-2.png" % randi_range(1,6))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event: InputEvent) -> void:
	if event.is_action("refresh_random"):
		_randomize()

func _play_end_note() -> void:
	pass
	
func _play_base_note() -> void:
	var note: String = keys[key][0];
	_sound_map(note)
	#if not %AudioStreamPlayer.playing:
#
	#else:
		## wait?
		#pass

func _play_note(num: int) -> void:
	#if not %AudioStreamPlayer.playing:
	var note: String = keys[key][num-1];
	_sound_map(note)
	#else:
		## wait?
		#pass


func _on_anchor_body_entered(body: Node2D) -> void:
	_play_base_note()
 # Replace with function body.


func _on_i_body_entered(body: Node2D) -> void:
	_play_note(1)

func _on_ii_body_entered(body: Node2D) -> void:
	_play_note(2)

func _on_iii_body_entered(body: Node2D) -> void:
	_play_note(3)

func _on_iv_body_entered(body: Node2D) -> void:
	_play_note(4)

func _on_v_body_entered(body: Node2D) -> void:
	_play_note(5)

func _on_vi_body_entered(body: Node2D) -> void:
	_play_note(6)

func _on_vii_body_entered(body: Node2D) -> void:
	_play_note(7)


func _on_end_anchor_body_entered(body: Node2D) -> void:
	pass
