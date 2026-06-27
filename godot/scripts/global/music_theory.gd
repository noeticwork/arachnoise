extends Node
## MusicTheory — global autoload
## Pure static data and computation. No signals, no state.
## All pitch inputs are MIDI pitch integers or pitch classes (0–11).
## All intervals are in semitones unless noted.

# ---------------------------------------------------------------------------
# Pitch class names
# ---------------------------------------------------------------------------
const NOTE_NAMES_SHARP: Array[String] = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
const NOTE_NAMES_FLAT:  Array[String] = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]

## Return the preferred spelling for a pitch class given a key context.
## key_pc: pitch class of the tonic. Uses flat names for flat keys, sharp for sharp keys.
static func note_name(pc: int, key_pc: int = 0) -> String:
	return NOTE_NAMES_FLAT[pc] if _key_uses_flats(key_pc) else NOTE_NAMES_SHARP[pc]

static func _key_uses_flats(key_pc: int) -> bool:
	# Flat keys: F Bb Eb Ab Db Gb (pitch classes 5,10,3,8,1,6)
	return key_pc in [5, 10, 3, 8, 1, 6]

# ---------------------------------------------------------------------------
# Circle of fifths
# ---------------------------------------------------------------------------
## Steps from C on the circle of fifths, indexed by pitch class.
## C=0 G=1 D=2 A=3 E=4 B=5 F#=6 C#=7 Ab=8 Eb=9 Bb=10 F=11
const FIFTHS_STEPS: Array[int] = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5]

## Pitch class at a given position on the circle of fifths (0=C, 1=G, etc.)
const FIFTHS_ORDER: Array[int] = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5]

## Clockwise distance between two pitch classes on the circle of fifths.
static func fifths_distance(from_pc: int, to_pc: int) -> int:
	return (FIFTHS_STEPS[to_pc] - FIFTHS_STEPS[from_pc] + 12) % 12

## Shortest (signed) distance: positive = clockwise (sharp), negative = anti-clockwise (flat).
static func fifths_distance_signed(from_pc: int, to_pc: int) -> int:
	var d := fifths_distance(from_pc, to_pc)
	return d if d <= 6 else d - 12

## Adjacent keys on the circle of fifths for a given tonic.
## Returns [dominant_pc, subdominant_pc] i.e. [one step sharp, one step flat]
static func adjacent_keys(tonic_pc: int) -> Array[int]:
	var step := FIFTHS_STEPS[tonic_pc]
	var dominant_pc    := FIFTHS_ORDER[(step + 1) % 12]
	var subdominant_pc := FIFTHS_ORDER[(step + 11) % 12]
	return [dominant_pc, subdominant_pc]

# ---------------------------------------------------------------------------
# Intervals
# ---------------------------------------------------------------------------
const INTERVAL_NAMES: Dictionary = {
	0:  "P1",   # perfect unison
	1:  "m2",   # minor second
	2:  "M2",   # major second
	3:  "m3",   # minor third
	4:  "M3",   # major third
	5:  "P4",   # perfect fourth
	6:  "TT",   # tritone
	7:  "P5",   # perfect fifth
	8:  "m6",   # minor sixth
	9:  "M6",   # major sixth
	10: "m7",   # minor seventh
	11: "M7",   # major seventh
	12: "P8",   # perfect octave
}

const INTERVAL_CONSONANCE: Dictionary = {
	0: 1.0,   # unison
	1: 0.1,   # m2 — very dissonant
	2: 0.3,   # M2
	3: 0.7,   # m3 — consonant
	4: 0.8,   # M3 — consonant
	5: 0.75,  # P4 — contextually consonant
	6: 0.0,   # TT — maximally dissonant
	7: 1.0,   # P5 — perfect consonance
	8: 0.65,  # m6
	9: 0.7,   # M6
	10: 0.2,  # m7 — mild dissonance
	11: 0.05, # M7 — strong dissonance
	12: 1.0,  # octave
}

## Interval in semitones between two pitch classes (always upward, 0–11).
static func interval_pc(a: int, b: int) -> int:
	return (b - a + 12) % 12

## Consonance score 0.0–1.0 for a semitone interval.
static func consonance(semitones: int) -> float:
	var s := semitones % 12
	return INTERVAL_CONSONANCE.get(s, 0.5)

## Consonance of a set of pitch classes (average of all dyad consonances).
static func chord_consonance(pitch_classes: Array[int]) -> float:
	if pitch_classes.size() < 2:
		return 1.0
	var total := 0.0
	var count := 0
	for i in pitch_classes.size():
		for j in range(i + 1, pitch_classes.size()):
			total += consonance(interval_pc(pitch_classes[i], pitch_classes[j]))
			count += 1
	return total / count

# ---------------------------------------------------------------------------
# Scales
# ---------------------------------------------------------------------------
## Interval patterns for common scales (semitones from root).
const SCALE_INTERVALS: Dictionary = {
	"major":           [0, 2, 4, 5, 7, 9, 11],
	"natural_minor":   [0, 2, 3, 5, 7, 8, 10],
	"harmonic_minor":  [0, 2, 3, 5, 7, 8, 11],
	"melodic_minor":   [0, 2, 3, 5, 7, 9, 11],
	"dorian":          [0, 2, 3, 5, 7, 9, 10],
	"phrygian":        [0, 1, 3, 5, 7, 8, 10],
	"lydian":          [0, 2, 4, 6, 7, 9, 11],
	"mixolydian":      [0, 2, 4, 5, 7, 9, 10],
	"locrian":         [0, 1, 3, 5, 6, 8, 10],
	"pentatonic_major":[0, 2, 4, 7, 9],
	"pentatonic_minor":[0, 3, 5, 7, 10],
	"blues":           [0, 3, 5, 6, 7, 10],
	"whole_tone":      [0, 2, 4, 6, 8, 10],
	"diminished":      [0, 2, 3, 5, 6, 8, 9, 11],
}

## Pitch classes for a scale given tonic and scale name.
static func scale_pitch_classes(tonic_pc: int, scale_name: String) -> Array[int]:
	var intervals: Array = SCALE_INTERVALS.get(scale_name, SCALE_INTERVALS["major"])
	var result: Array[int] = []
	for i in intervals:
		result.append((tonic_pc + i) % 12)
	return result

## Check if a pitch class belongs to a given scale.
static func in_scale(pc: int, tonic_pc: int, scale_name: String = "major") -> bool:
	return scale_pitch_classes(tonic_pc, scale_name).has(pc)

## Scale degree (1-indexed) of a pitch class within a scale, or -1 if not in scale.
static func scale_degree(pc: int, tonic_pc: int, scale_name: String = "major") -> int:
	var pcs := scale_pitch_classes(tonic_pc, scale_name)
	var idx := pcs.find(pc)
	return idx + 1 if idx >= 0 else -1

# ---------------------------------------------------------------------------
# Key signatures
# ---------------------------------------------------------------------------
## Number of sharps (positive) or flats (negative) in a major key.
const KEY_SIGNATURE: Dictionary = {
	0:  0,   # C  — no accidentals
	7:  1,   # G  — 1 sharp
	2:  2,   # D  — 2 sharps
	9:  3,   # A  — 3 sharps
	4:  4,   # E  — 4 sharps
	11: 5,   # B  — 5 sharps
	6:  6,   # F# — 6 sharps
	1:  7,   # C# — 7 sharps
	5:  -1,  # F  — 1 flat
	10: -2,  # Bb — 2 flats
	3:  -3,  # Eb — 3 flats
	8:  -4,  # Ab — 4 flats
}

static func key_signature(tonic_pc: int) -> int:
	return KEY_SIGNATURE.get(tonic_pc, 0)

## Relative minor tonic for a major key.
static func relative_minor(major_tonic_pc: int) -> int:
	return (major_tonic_pc + 9) % 12

## Relative major tonic for a minor key.
static func relative_major(minor_tonic_pc: int) -> int:
	return (minor_tonic_pc + 3) % 12

# ---------------------------------------------------------------------------
# Diatonic chords
# ---------------------------------------------------------------------------
## Roman numeral labels for diatonic triads in a major key.
const MAJOR_DIATONIC_QUALITIES: Array[String] = ["maj","min","min","maj","maj","min","dim"]
const ROMAN_NUMERALS: Array[String]            = ["I","ii","iii","IV","V","vi","vii°"]

## Returns the diatonic chord roots (pitch classes) for a major key.
static func diatonic_roots(tonic_pc: int) -> Array[int]:
	var major := SCALE_INTERVALS["major"]
	var result: Array[int] = []
	for i in major:
		result.append((tonic_pc + i) % 12)
	return result

## Roman numeral for a chord root within a key, or "" if not diatonic.
static func roman_numeral(chord_root_pc: int, key_tonic_pc: int) -> String:
	var roots := diatonic_roots(key_tonic_pc)
	var idx := roots.find(chord_root_pc)
	return ROMAN_NUMERALS[idx] if idx >= 0 else ""

## Chord function: "tonic", "subdominant", "dominant", or "chromatic".
static func chord_function(chord_root_pc: int, key_tonic_pc: int) -> String:
	var degree := scale_degree(chord_root_pc, key_tonic_pc, "major")
	match degree:
		1, 3, 6: return "tonic"
		2, 4:    return "subdominant"
		5, 7:    return "dominant"
		_:       return "chromatic"

## Diatonic quality of a chord at a given scale degree in a major key.
static func diatonic_quality(scale_deg: int) -> String:
	if scale_deg < 1 or scale_deg > 7:
		return "unknown"
	return MAJOR_DIATONIC_QUALITIES[scale_deg - 1]

# ---------------------------------------------------------------------------
# Harmonic tension
# ---------------------------------------------------------------------------
## Tension score 0.0–1.0: how strongly a chord wants to resolve.
## Based on chord function and quality.
static func harmonic_tension(chord_root_pc: int, quality: String, key_tonic_pc: int) -> float:
	var func_name := chord_function(chord_root_pc, key_tonic_pc)
	var base: float
	match func_name:
		"tonic":       base = 0.1
		"subdominant": base = 0.5
		"dominant":    base = 0.8
		_:             base = 0.9   # chromatic
	# Quality modifier
	match quality:
		"dom7":  base = minf(base + 0.15, 1.0)
		"dim", "dim7": base = minf(base + 0.2, 1.0)
		"aug":   base = minf(base + 0.1, 1.0)
		"maj", "maj7": base = maxf(base - 0.05, 0.0)
	return base

# ---------------------------------------------------------------------------
# Pitch utilities
# ---------------------------------------------------------------------------
## Pitch class from MIDI pitch.
static func pitch_class(midi_pitch: int) -> int:
	return midi_pitch % 12

## Octave from MIDI pitch (middle C = octave 4).
static func octave(midi_pitch: int) -> int:
	return (midi_pitch / 12) - 1

## MIDI pitch from pitch class and octave.
static func midi_pitch(pc: int, oct: int) -> int:
	return (oct + 1) * 12 + pc

## Semitone distance (shortest path) between two MIDI pitches.
static func semitone_distance(a: int, b: int) -> int:
	return abs(a - b)

## Enharmonic equivalence check.
static func enharmonic(pc_a: int, pc_b: int) -> bool:
	return pc_a % 12 == pc_b % 12

# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------
static func describe_chord(root_pc: int, quality: String, key_tonic_pc: int) -> String:
	var name_str  := NOTE_NAMES_SHARP[root_pc] + quality
	var roman     := roman_numeral(root_pc, key_tonic_pc)
	var func_str  := chord_function(root_pc, key_tonic_pc)
	var tension   := harmonic_tension(root_pc, quality, key_tonic_pc)
	var key_name  := NOTE_NAMES_SHARP[key_tonic_pc]
	return "%s  (%s in %s)  func=%s  tension=%.2f" % [name_str, roman, key_name, func_str, tension]
