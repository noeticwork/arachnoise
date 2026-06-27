extends Node2D

func _ready() -> void:
	add_drawers() 

func _process(delta: float) -> void:
	pass

func get_ropes() -> Array:
	return $WindArea2D.find_children("Rope2D")

func add_drawers():
	for rope: Rope2D in get_ropes():
		var drawer := RopeDrawSimpleLine.new(rope)
		rope.add_child(drawer)

	get_tree().debug_collisions_hint = false
	get_tree().root.propagate_call("queue_redraw")
