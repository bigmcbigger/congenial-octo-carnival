extends Node2D

@export var level_scene: PackedScene;
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_pressed():
	get_tree().change_scene_to_packed(level_scene)
