extends Node2D
@onready var line_texture: TextureRect = %LineTexture


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	line_texture.texture = load("res://assets/line%dd-2.png" % randi_range(1,6))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
