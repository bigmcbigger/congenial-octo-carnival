extends TextureProgressBar

var bar_green = preload("res://art/healthbar/green.png")
var bar_yellow = preload("res://art/healthbar/yellow.png")
var bar_red = preload("res://art/healthbar/red.png")

func update_bar(_value, _max_value):
	value = _value
	#if value < _max_value:
		#show()
	texture_progress = bar_green
	if value < 0.75 * _max_value:
		texture_progress = bar_yellow
	if value < 0.45 * _max_value:
		texture_progress = bar_red
