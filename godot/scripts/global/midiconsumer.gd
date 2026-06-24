extends Node

# ---------------------------------------------------------------------------
# Example: connect to MidiInputManager from any scene node
# MidiInputManager must be registered as an autoload in Project Settings.
# ---------------------------------------------------------------------------

func _ready() -> void:
	MidiInputManager.note_on.connect(_on_note_on)
	MidiInputManager.note_off.connect(_on_note_off)
	MidiInputManager.chord_played.connect(_on_chord_played)
	MidiInputManager.pad_hit.connect(_on_pad_hit)
	MidiInputManager.pitch_bend_changed.connect(_on_pitch_bend)
	MidiInputManager.mod_changed.connect(_on_mod)

func _on_note_on(pitch: int, velocity: int, channel: int) -> void:
	_printt("note_on  pitch=%d  vel=%d  ch=%d" % [pitch, velocity, channel])
	# → highlight key on projector, trigger audio, etc.

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
	$RichTextLabel.text += "\r\n" + args
