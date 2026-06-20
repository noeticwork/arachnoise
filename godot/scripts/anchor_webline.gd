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

# Returns the full asset path for a chord, or empty string if not found.
func get_chord_asset_path(chord: String) -> String:
	# 1. Detect the root and quality
	var root: String
	var quality: String

	if chord.ends_with("dim"):
		root = chord.trim_suffix("dim")
		quality = "dim"
	elif chord.ends_with("m"):
		root = chord.trim_suffix("m")
		quality = "min"
	else:
		root = chord
		quality = "maj"

	# 2. Build the filename we expect
	var filename = root + quality + ".wav"

	# 3. (Optional) Handle common enharmonic fallbacks
	#    Add more if needed – these map chord names that don't exist
	#    in your file list to the files you DO have.
	var enharmonic_fallbacks = {
		"Abm": "G#min",   # Ab minor = G# minor
		"Cb":  "Bmaj",    # Cb major = B major
		"E#dim": "Fdim",  # E# dim = F dim
		# If you need Abdim as well, but you have Abdim.wav, so it's fine.
	}
	if not FileAccess.file_exists("res://assets/audio/Pads/" + filename):
		var fallback = enharmonic_fallbacks.get(root + quality)
		if fallback:
			filename = fallback + ".wav"

	# 4. Full path
	var full_path = "res://assets/audio/Pads/" + filename
	if FileAccess.file_exists(full_path):
		return full_path
	else:
		push_error("Sound file not found: " + full_path)
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
		# Optional: auto‑free when done
		#player.finished.connect(player.queue_free)

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

func _on_ii_area_entered(area: Area2D) -> void:
	_play_note(2)

func _on_iii_area_entered(area: Area2D) -> void:
	_play_note(3)

func _on_iv_area_entered(area: Area2D) -> void:
	_play_note(4)

func _on_v_area_entered(area: Area2D) -> void:
	_play_note(5)

func _on_vi_area_entered(area: Area2D) -> void:
	_play_note(6)

func _on_vii_area_entered(area: Area2D) -> void:
	_play_note(7)

func _on_end_anchor_area_entered(area: Area2D) -> void:
	_play_end_note()


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
