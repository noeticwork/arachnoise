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
	if not %AudioStreamPlayer.playing:
		var note: String = keys[key][0];
		%AudioStreamPlayer.stream = load("res://assets/audio/Notes/Celeste/OCT1 31 Celeste%s1.wav" % note)
	else:
		# wait?
		pass

func _play_note(num: int) -> void:
	if not %AudioStreamPlayer.playing:
		var note: String = keys[key][num];
		%AudioStreamPlayer.stream = load("res://assets/audio/Notes/Celeste/OCT1 31 Celeste%s1.wav" % note)
	else:
		# wait?
		pass

func _on_anchor_area_entered(area: Area2D) -> void:
	_play_base_note()

func _on_i_area_entered(area: Area2D) -> void:
	_play_note(1)

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
