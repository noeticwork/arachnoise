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
