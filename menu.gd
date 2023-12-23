extends Node2D

@export var level_scene: PackedScene;
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var size = null
func _process(delta):
	# TODO figure out the right way to do this :D
	var new_size = get_viewport().size
	if size != new_size:
		size = new_size;
		$CenterContainer.set_size(size)
	pass

func start_pressed():
	get_tree().change_scene_to_packed(level_scene)
