extends Control

onready var threed_view = $"ContainerSplitView/Container3DView/ContainerViewport/Viewport/Spatial"
onready var shape_keys_editor = $"ContainerSplitView/ContainerUI/ShapeKeys"

const threed_view_class = preload("res://TestModel/3DView.gd")

var emotions_list:threed_view_class.Emotions

onready var ui_emotions_list = $ContainerSplitView/ContainerUI/VBoxContainer/EmotionList


func show_blendshapes():
	var blendshapes = threed_view.get_blendshapes()
	threed_view.attach_blendshapes(blendshapes)
	blendshapes.reset()
	shape_keys_editor.list_blendshapes(blendshapes)

func load_emotions_or_default(model_path:String):
	var save_file = File.new()
	var err = save_file.open("user://emotes.json", File.READ)

	var could_read_file:bool = (err == OK)
	var json_ok:bool = true
	var emotions:threed_view_class.Emotions

	if could_read_file:
		var content:String = save_file.get_as_text()
		save_file.close()
		var result:JSONParseResult = JSON.parse(content)
		json_ok = (result.error == OK)
		if result.error != OK:
			printerr(
				"While parsing emotion, error " + str(result.error) + ".\n" +
				"At line " + str(result.error_line) + " :\n" +
				result.error_string)
			json_ok = false

		# We expect an Array. If it's not an Array, forget about it
		if json_ok:
			emotions = threed_view_class.Emotions.from_serialized(result.result)
		else:
			json_ok = false
	else:
		printerr("Could not read emotes.json")

	if not could_read_file or not json_ok:
		if save_file.open("user://emotes.json", File.WRITE) == OK:
			save_file.store_string(to_json(threed_view_class.Emotions.new().serialize()))
			save_file.close()
			printerr("Recursing")
			load_emotions_or_default(model_path)
			return
		else:
			printerr("Could not read the motions files and could not recreate it")
			return

	emotions_list = emotions

func save_emotions(emotions:threed_view_class.Emotions) -> int:
	var save_file:File = File.new()
	var err:int = save_file.open("user://emotes.json", File.READ_WRITE)
	if err != OK:
		printerr("Could not save the emotions list")
		printerr("Error code : " + str(err))
		return err

	save_file.store_string(to_json(emotions.serialize()))
	save_file.close()
	return OK



func list_emotions():
	ui_emotions_list.clear()
	for emotion in emotions_list.data:
		ui_emotions_list.add_item(emotion.emotion_name)

func _manage_dropped_files(filepaths:PoolStringArray, screen) -> void:
	var filepath:String = filepaths[0]
	if filepath.ends_with(".glb"):
		print("Trying to load " + filepath)
		threed_view.add_glb_model(filepath)
	print(filepath)

func _model_loading_start():
	printerr("Loading model")

func _model_loading_stop():
	printerr("Loading model ended")

func _ready():
	# use the dir of the model loaded by drag and drop
	load_emotions_or_default("")
	list_emotions()
	get_tree().connect("files_dropped", self, "_manage_dropped_files")
	threed_view.connect("model_loading_start", self, "_model_loading_start")
	threed_view.connect("model_loading_ended", self, "_model_loading_stop")
	#show_blendshapes()

func _on_Button_pressed():
	threed_view.camera_face()

func _on_Button2_pressed():
	threed_view.camera_full_body()

func _on_ShapeKeys_save_requested(
	emotion_new_name:String,
	emotion:threed_view_class.Emotion):

	emotion.emotion_name = emotion_new_name
	emotion.blendshapes.refresh_values()
	if save_emotions(emotions_list) != OK:
		printerr("Could not save the emotions list")
	show_emotions_list()

func show_emotions_list():
	$ContainerSplitView/ContainerUI.current_tab = 0
	list_emotions()

func show_emotion_editor():
	$ContainerSplitView/ContainerUI.current_tab = 1

func _start_editing_emotion(emotion:threed_view_class.Emotion):
	# Even if we show the current emotion, we still limit ourselves
	# to the current model blendshapes.
	# We'll tackle corner cases later.
	var edited_blendshapes:threed_view_class.Blendshapes = threed_view.get_blendshapes()
	threed_view.attach_blendshapes(edited_blendshapes)
	shape_keys_editor.edit_emotion(edited_blendshapes, emotion.emotion_name)
	shape_keys_editor.disconnect(
		"save_requested", self, "_on_ShapeKeys_save_requested")
	shape_keys_editor.connect(
		"save_requested", self,
		"_on_ShapeKeys_save_requested", [emotion])
	show_emotion_editor()

func _on_ButtonAdd_pressed():
	threed_view.reset_emotion()
	var emotion = emotions_list.add_new(threed_view.get_blendshapes())
	_start_editing_emotion(emotion)


func _on_ItemList_item_activated(emotion_idx:int):
	_start_editing_emotion(emotions_list.get_emotion(emotion_idx))
	pass # Replace with function body.


func _on_EmotionList_item_selected(emotion_idx:int):
	var emotion = emotions_list.get_emotion(emotion_idx)
	threed_view.current_emotion(emotion)
	pass # Replace with function body.
