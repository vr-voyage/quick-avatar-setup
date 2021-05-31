extends HBoxContainer

#signal blendshape_enable(blendshape_name, blendshape_idx)
#signal blendshape_selected(blendshape_name, blendshape_idx)

const threed_view = preload("res://TestModel/3DView.gd")

var blendshape:threed_view.Blendshape = threed_view.Blendshape.new("","")

func setup() -> void:
	$Label.text = blendshape.blendshape_name
	# Why not 0 ? I'm worried about weird rounding results
	# that would cause the value to be at 0.00001 instead of 0
	$CheckButton.pressed = (blendshape.current_value > 0.01)
	print("blendshape : " + blendshape.blendshape_name + " -> " + str(blendshape.current_value))

func set_blendshape(new_blendshape:threed_view.Blendshape) -> void:
	blendshape = new_blendshape
	setup()

func _on_CheckButton_toggled(button_pressed):
	blendshape.set_to(float(button_pressed))

func _on_ShapekeyTestButton_focus_entered():
	pass
