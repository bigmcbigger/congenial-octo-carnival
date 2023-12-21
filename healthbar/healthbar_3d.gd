extends Sprite3D

func _ready():
	texture = $SubViewport.get_texture()

func update(value, max_value):
	$SubViewport/Healthbar2D.update_bar(value, max_value)
