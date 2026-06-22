extends Node

var chimes: Dictionary = {}
func _ready() -> void:

	var instruments = {
		"celeste": "Celeste",
		"harp":    "Harp"
	}
	var roots = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]
	var base_path = "res://assets/audio/Chords/Chords "  # matches your file names

	for inst_key in instruments:
		var inst_prefix = instruments[inst_key]
		for root in roots:
			var file_name = inst_prefix + "Chord" + root + ".wav"
			var full_path = base_path + file_name
			var key = inst_key + "_" + root          # e.g. "celeste_C", "harp_G#"

			var stream = load(full_path)
			if stream:
				_register(key, stream)
			else:
				push_error("Failed to load: " + full_path)

func _register(name: String, stream: AudioStream) -> void:
	chimes[name] = stream

func play(name: String, bus: StringName = &"Master") -> AudioStreamPlayer:
	if not chimes.has(name):
		push_warning("AudioManager: unknown sample '%s'" % name)
		return null
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = chimes[name]
	player.bus = bus
	player.play()
	#print("Playing ", name)
	# auto-free when done
	player.finished.connect(player.queue_free)
	return player
