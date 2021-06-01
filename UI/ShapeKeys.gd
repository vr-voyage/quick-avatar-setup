extends HBoxContainer

const shapekey_button:PackedScene = preload("res://UI/WidgetShapekeyTester.tscn")
const threed_view_class = preload("res://TestModel/3DView.gd")

onready var ui_blendshapes_list = $ContainerEditedAnimation/ScrollingList/ListShapekeys
onready var ui_emotion_name_input = $ContainerEditedAnimation/HBoxContainer/EmotionName
onready var ui_save_button = $ContainerEditedAnimation/HBoxContainer/ButtonSave

signal save_requested(emotion_name)

func _ready():
	ui_save_button.disabled = true

func clear_list():
	var children = ui_blendshapes_list.get_children()
	for child in children:
		ui_blendshapes_list.remove_child(child)

func list_blendshapes(blendshapes:threed_view_class.Blendshapes) -> void:
	clear_list()
	ui_save_button.disabled = false
	for blendshape in blendshapes.data:
		var button = shapekey_button.instance()
		ui_blendshapes_list.add_child(button)
		button.set_blendshape(blendshape)

func edit_emotion(blendshapes:threed_view_class.Blendshapes, emotion_name:String) -> void:
	ui_emotion_name_input.text = emotion_name
	# Make sure we're showing the blendshapes with their actual values
	blendshapes.refresh_values()
	list_blendshapes(blendshapes)

func _on_ButtonSave_pressed():
	emit_signal("save_requested", ui_emotion_name_input.text)
