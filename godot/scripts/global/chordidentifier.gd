class_name ChordIdentifier

# ---------------------------------------------------------------------------
# Interval sets for triads and 7th chords (as sorted pitch-class sets)
# Root is always pitch class 0 in the interval set.
# ---------------------------------------------------------------------------
const CHORD_PATTERNS: Array[Dictionary] = [
	# Triads
	{ "intervals": [0, 4, 7],       "quality": "maj",   "suffix": "" },
	{ "intervals": [0, 3, 7],       "quality": "min",   "suffix": "m" },
	{ "intervals": [0, 3, 6],       "quality": "dim",   "suffix": "dim" },
	{ "intervals": [0, 4, 8],       "quality": "aug",   "suffix": "aug" },
	{ "intervals": [0, 5, 7],       "quality": "sus4",  "suffix": "sus4" },
	{ "intervals": [0, 2, 7],       "quality": "sus2",  "suffix": "sus2" },
	# 7th chords
	{ "intervals": [0, 4, 7, 11],   "quality": "maj7",  "suffix": "maj7" },
	{ "intervals": [0, 4, 7, 10],   "quality": "dom7",  "suffix": "7" },
	{ "intervals": [0, 3, 7, 10],   "quality": "min7",  "suffix": "m7" },
	{ "intervals": [0, 3, 6, 10],   "quality": "m7b5",  "suffix": "m7b5" },
	{ "intervals": [0, 3, 6, 9],    "quality": "dim7",  "suffix": "dim7" },
	{ "intervals": [0, 4, 8, 10],   "quality": "aug7",  "suffix": "aug7" },
	{ "intervals": [0, 3, 7, 11],   "quality": "minmaj7","suffix": "mM7" },
]

const NOTE_NAMES := ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
static func identify(pitches: Array[int]) -> Dictionary:
	# Returns { root: int, quality: String, name: String }
	# root is the MIDI pitch number of the identified root.

	if pitches.is_empty():
		return { "root": -1, "quality": "unknown", "name": "?" }

	# Reduce to unique pitch classes
	var classes: Array[int] = _unique_classes(pitches)

	# Try every pitch class as candidate root
	for candidate_root in classes:
		var intervals := _normalise(classes, candidate_root)
		for pattern in CHORD_PATTERNS:
			if intervals == pattern.intervals:
				var root_name = NOTE_NAMES[candidate_root]
				return {
					"root":    candidate_root,
					"quality": pattern.quality,
					"name":    root_name + pattern.suffix
				}

	# Fallback: return lowest note as root, quality unknown
	var lowest_class := pitches[0] % 12
	return {
		"root":    lowest_class,
		"quality": "unknown",
		"name":    NOTE_NAMES[lowest_class] + "?"
	}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
static func _unique_classes(pitches: Array[int]) -> Array[int]:
	var seen: Dictionary = {}
	for p in pitches:
		seen[p % 12] = true
	var result: Array[int] = []
	for k in seen:
		result.append(k)
	result.sort()
	return result

static func _normalise(classes: Array[int], root: int) -> Array[int]:
	var result: Array[int] = []
	for c in classes:
		result.append((c - root + 12) % 12)
	result.sort()
	return result
