extends Control

onready var threed_view = $"ContainerSplitView/Container3DView/ContainerViewport/Viewport/Spatial"
onready var shape_keys_editor = $"ContainerSplitView/ContainerUI/ShapeKeys"

const threed_view_class = preload("res://TestModel/3DView.gd")

var avatar_setup:threed_view_class.AvatarSetup

onready var ui_emotions_list = $ContainerSplitView/ContainerUI/Emotions/EmotionList
onready var ui_viewport_spatial = $ContainerSplitView/Container3DView/ContainerViewport/Viewport/Spatial

var current_model_filepath:String = ""
var current_avatar_setup_filepath:String = ""

func show_blendshapes():
	var blendshapes = threed_view.get_blendshapes()
	threed_view.attach_blendshapes(blendshapes)
	blendshapes.reset()
	shape_keys_editor.list_blendshapes(blendshapes)

func load_emotions_or_default(avatar_setup_file_path:String):
	var save_file = File.new()
	var err = save_file.open(avatar_setup_file_path, File.READ)

	var could_read_file:bool = (err == OK)
	var json_ok:bool = true
	var saved_setup:threed_view_class.AvatarSetup

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

		# Basic checks
		if json_ok and result.result is Dictionary and result.result.has("emotions"):
			saved_setup = threed_view_class.AvatarSetup.from_serialized(result.result)
			# emotions = threed_view_class.Emotions.from_serialized(result.result)
		else:
			json_ok = false
	else:
		printerr("Could not read emotes.json")

	if not could_read_file or not json_ok:
		if save_file.open(avatar_setup_file_path, File.WRITE) == OK:
			save_file.store_string(to_json(threed_view_class.AvatarSetup.new().serialize()))
			save_file.close()
			printerr("Recursing")
			load_emotions_or_default(avatar_setup_file_path)
			return
		else:
			printerr("Could not read the emotions files and could not recreate it")
			return

	avatar_setup = saved_setup

func save_setup(avatar_setup:threed_view_class.AvatarSetup) -> int:
	var save_file:File = File.new()
	# Note : Do NOT use READ_WRITE, the overwriting might be incomplete, leaving
	# previous bits of the old save, leading to invalid JSON files
	var err:int = save_file.open(current_avatar_setup_filepath, File.WRITE)
	if err != OK:
		printerr("Could not save the emotions list")
		printerr("Error code : " + str(err))
		return err

	save_file.store_string(to_json(avatar_setup.serialize()))
	save_file.close()

	print("Emotions saved to " + current_avatar_setup_filepath)
	return OK

func list_emotions():
	ui_emotions_list.clear()
	for emotion in avatar_setup.emotions.data:
		ui_emotions_list.add_item(emotion.emotion_name)

func _manage_dropped_files(filepaths:PoolStringArray, screen) -> void:
	var filepath:String = filepaths[0]
	if filepath.ends_with(".glb"):
		current_model_filepath = filepath
		print("Trying to load " + filepath)
		threed_view.add_glb_model(filepath)
	
	if filepath.ends_with(".vrm"):
		current_model_filepath = filepath
		threed_view.add_vrm_model(filepath)

	print(filepath)

func _model_loading_start():
	printerr("Loading model")

func _model_emotes_json_filepath() -> String:
	return current_model_filepath + ".avatar_setup.json"

func _model_loading_stop():
	printerr("Loading model ended")
	current_avatar_setup_filepath = _model_emotes_json_filepath()
	load_emotions_or_default(current_avatar_setup_filepath)
	list_emotions()
	editor_emotions_enable()

func editor_emotions_set_useable(state:bool):
	# FIXME Hack for first release
	# Make the emotions tab its own object. Call disable on it.
	$ContainerSplitView/ContainerUI/Emotions/ButtonAdd.disabled    = !state
	$ContainerSplitView/ContainerUI/Emotions/ButtonDelete.disabled = !state

func editor_emotions_enable():
	editor_emotions_set_useable(true)

func editor_emotions_disable():
	editor_emotions_set_useable(false)

func enable_editors():
	editor_emotions_enable()

func disable_editors():
	editor_emotions_disable()

func _ready():
	disable_editors()
	get_tree().connect("files_dropped", self, "_manage_dropped_files")
	threed_view.connect("model_loading_start", self, "_model_loading_start")
	threed_view.connect("model_loading_ended", self, "_model_loading_stop")

func _on_Button_pressed():
	threed_view.select_camera_face()

func _on_Button2_pressed():
	threed_view.select_camera_full_body()

func _on_ShapeKeys_save_requested(
	emotion_new_name:String,
	emotion:threed_view_class.Emotion):

	emotion.emotion_name = emotion_new_name
	threed_view.attach_blendshapes(emotion.blendshapes)
	emotion.blendshapes.refresh_values()

	# FIXME Show a big error popup !
	if save_setup(avatar_setup) != OK:
		printerr("Could not save the curernt avatar setup")
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
	var emotion = avatar_setup.emotions.add_new(threed_view.get_new_blendshapes())
	_start_editing_emotion(emotion)

func _on_ItemList_item_activated(emotion_idx:int):
	_start_editing_emotion(avatar_setup.emotions.get_emotion(emotion_idx))
	pass # Replace with function body.


func _on_EmotionList_item_selected(emotion_idx:int):
	var emotion = avatar_setup.emotions.get_emotion(emotion_idx)
	threed_view.current_emotion(emotion)
	pass # Replace with function body.

func _on_ButtonDelete_pressed():
	avatar_setup.emotions.delete_emotion(ui_emotions_list.get_selected_items()[0])
	list_emotions()
	save_setup(avatar_setup)
	pass # Replace with function body.


func _on_ContainerViewport_gui_input(event):
	ui_viewport_spatial._gui_input(event)
	pass # Replace with function body.
