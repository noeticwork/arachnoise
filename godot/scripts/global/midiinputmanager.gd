extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal note_on(pitch: int, velocity: int, channel: int)
signal note_off(pitch: int, channel: int)
signal chord_played(notes: Array[int], root: int, quality: String, name: String)
signal pad_hit(pad_index: int, velocity: int)
signal pitch_bend_changed(value: float)   # normalised -1.0 .. 1.0
signal mod_changed(value: float)          # normalised  0.0 .. 1.0

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
const AGGREGATION_MS   := 50    # window to collect simultaneous note-ons
const HOLD_MS          := 300   # notes must be held this long before chord fires
const MIN_CHORD_NOTES  := 3

# MPK Mini II pads arrive on channel 10 (0-indexed: 9), notes 36-43
const PAD_CHANNEL      := 9
const PAD_NOTE_MIN     := 36
const PAD_NOTE_MAX     := 43

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _held_notes: Dictionary = {}          # pitch -> true
var _pending_notes: Array[int] = []       # notes in current aggregation window
var _agg_timer: SceneTreeTimer = null
var _hold_timer: SceneTreeTimer = null
var _chord_armed: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	OS.open_midi_inputs()
	var inputs := OS.get_connected_midi_inputs()
	if inputs.is_empty():
		push_warning("MidiInputManager: no MIDI inputs found")
	else:
		print("MidiInputManager: found %d input(s): %s" % [inputs.size(), inputs])

func _input(event: InputEvent) -> void:
	if not event is InputEventMIDI:
		return
	var m: InputEventMIDI = event
	match m.message:
		MIDI_MESSAGE_NOTE_ON:
			if m.velocity == 0:
				_handle_note_off(m.pitch, m.channel)
			else:
				_handle_note_on(m.pitch, m.velocity, m.channel)
		MIDI_MESSAGE_NOTE_OFF:
			_handle_note_off(m.pitch, m.channel)
		MIDI_MESSAGE_PITCH_BEND:
			# raw value 0-16383; centre 8192
			pitch_bend_changed.emit((m.pitch - 8192.0) / 8192.0)
		MIDI_MESSAGE_CONTROL_CHANGE:
			if m.controller_number == 1:  # CC1 = mod wheel
				mod_changed.emit(m.controller_value / 127.0)

# ---------------------------------------------------------------------------
# Note on / off
# ---------------------------------------------------------------------------
func _handle_note_on(pitch: int, velocity: int, channel: int) -> void:
	# Pads: separate signal, excluded from chord logic
	if channel == PAD_CHANNEL and pitch >= PAD_NOTE_MIN and pitch <= PAD_NOTE_MAX:
		pad_hit.emit(pitch - PAD_NOTE_MIN, velocity)
		return

	_held_notes[pitch] = true
	note_on.emit(pitch, velocity, channel)

	_pending_notes.append(pitch)

	# Cancel any existing hold timer — new note resets it
	_chord_armed = false
	if _hold_timer:
		_hold_timer = null

	# Start or extend aggregation window
	if _agg_timer == null:
		_agg_timer = get_tree().create_timer(AGGREGATION_MS / 1000.0)
		_agg_timer.timeout.connect(_on_agg_timeout)

func _handle_note_off(pitch: int, channel: int) -> void:
	if channel == PAD_CHANNEL:
		return
	_held_notes.erase(pitch)
	note_off.emit(pitch, channel)

	# If chord was armed and a note releases, disarm (chord wasn't held long enough)
	if _chord_armed:
		_chord_armed = false
		_hold_timer = null

# ---------------------------------------------------------------------------
# Chord detection timers
# ---------------------------------------------------------------------------
func _on_agg_timeout() -> void:
	_agg_timer = null

	if _pending_notes.size() < MIN_CHORD_NOTES:
		_pending_notes.clear()
		return

	# Snapshot and start hold timer
	var snapshot := _pending_notes.duplicate()
	_pending_notes.clear()
	_chord_armed = true

	_hold_timer = get_tree().create_timer(HOLD_MS / 1000.0)
	_hold_timer.timeout.connect(_on_hold_timeout.bind(snapshot))

func _on_hold_timeout(snapshot: Array) -> void:
	_hold_timer = null
	if not _chord_armed:
		return
	_chord_armed = false

	# All snapshot notes must still be held
	for pitch in snapshot:
		if not _held_notes.has(pitch):
			return

	_emit_chord(snapshot)

func _emit_chord(pitches: Array) -> void:
	var typed: Array[int] = []
	for p in pitches:
		typed.append(p)

	var result := ChordIdentifier.identify(typed)
	chord_played.emit(typed, result.root, result.quality, result.name)
