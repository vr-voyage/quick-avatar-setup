extends HBoxContainer

#signal blendshape_enable(blendshape_name, blendshape_idx)
#signal blendshape_selected(blendshape_name, blendshape_idx)

const threed_view = preload("res://TestModel/3DView.gd")

var blendshape:threed_view.Blendshape = threed_view.Blendshape.new("","")

func _enter_tree():
	$ShapeKeySlider.connect("value_changed", self, "_on_ShapeKeySlider_value_changed")

func update_slider_silently(value:float):
	$ShapeKeySlider.disconnect("value_changed", self, "_on_ShapeKeySlider_value_changed")
	$ShapeKeySlider.value = value
	$ShapeKeySlider.connect("value_changed", self, "_on_ShapeKeySlider_value_changed")

func setup() -> void:
	$Label.text = blendshape.blendshape_name
	# Why not 0 ? I'm worried about weird rounding results
	# that would cause the value to be at 0.00001 instead of 0
	$ShapeKeyWeight.value = blendshape.current_value

func set_blendshape(new_blendshape:threed_view.Blendshape) -> void:
	blendshape = new_blendshape
	setup()

func _on_CheckButton_toggled(button_pressed):
	var user_change:bool = (
		(button_pressed and $ShapeKeyWeight.value < 0.01) or
		((not button_pressed) and $ShapeKeyWeight.value > 0.01)
	)

	if user_change:
		$ShapeKeyWeight.value = float(button_pressed)

func _on_ShapeKeyWeight_value_changed(value):

	$CheckButton.pressed = (value > 0.01)
	update_slider_silently(value)
	blendshape.set_to(value)

func _on_ShapeKeySlider_value_changed(value):
	printerr(value)
	$ShapeKeyWeight.value = value

