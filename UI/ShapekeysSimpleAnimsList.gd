extends VBoxContainer

var current_names_list:PoolStringArray = PoolStringArray()

signal animation_name_added(anim_name, current_names_list)
signal animation_name_removed(anim_name, current_names_list)
signal animation_name_changed(old_anim_name, new_anim_name, current_names_list)

onready var ui_text_anim_name = $ContainerAnimationNameEditor/TextAnimationName
onready var ui_list_anim_names = $AnimationNames

func refresh_list() -> void:
	ui_list_anim_names.clear()
	for anim_name in current_names_list:
		ui_list_anim_names.add_item(anim_name)

func set_anims_list(names_list:PoolStringArray) -> void:
	current_names_list = names_list
	refresh_list()

func animation_list_add_name(animation_name:String) -> void:
	current_names_list.append(animation_name)
	emit_signal("animation_name_added", animation_name, current_names_list)

func animation_name_index(animation_name:String) -> int:
	for idx in range(0, current_names_list.size()):
		if current_names_list[idx] == animation_name:
			return idx
	return -1

func animation_list_remove_name(animation_name:String) -> void:
	var idx:int = animation_name_index(animation_name)
	if idx != -1:
		current_names_list.remove(idx)
		emit_signal("ainmation_name_removed", animation_name, current_names_list)
	else:
		print_debug("Animation name unknown : " + str(animation_name))

func animation_list_name_change(old_animation_name:String, new_animation_name:String):
	var idx:int = animation_name_index(old_animation_name)
	if idx != -1:
		current_names_list[idx] = new_animation_name
		emit_signal("animation_name_changed", old_animation_name, new_animation_name, current_names_list)
	else:
		print_debug("Animation name unknown : " + str(old_animation_name))

func _ready():
	refresh_list()

func ui_add_name(animation_name):
	var anim_idx:int = animation_name_index(animation_name)
	if anim_idx == -1:
		anim_idx = current_names_list.size()
		animation_list_add_name(animation_name)
		refresh_list()
	ui_list_anim_names.select(anim_idx)

func ui_replace_name(old_name, new_name):
	animation_list_name_change(old_name, new_name)
	refresh_list()

func ui_remove_names(animation_names):
	for animation_name in animation_names:
		animation_list_remove_name(animation_name)
	refresh_list()

func _on_TextAnimationName_text_entered(animation_name):
	ui_add_name(animation_name)

func _on_ButtonAnimationNameSet_pressed():
	ui_add_name(ui_text_anim_name.text)

func ui_selected_names_get() -> PoolStringArray:
	var selected_indices:PoolIntArray = ui_list_anim_names.get_selected_items()
	var animation_names:PoolStringArray = PoolStringArray()
	for selected_idx in selected_indices:
		animation_names.append(ui_list_anim_names.get_item_text(selected_idx))
	return animation_names

func _on_RemoveAninmation_pressed():
	ui_remove_names(ui_selected_names_get())

func _on_AnimationNames_item_selected(index):
	ui_text_anim_name.text = ui_list_anim_names.get_item_text(index)

func _on_ButtonRename_pressed():
	var new_name:String = ui_text_anim_name.text
	animation_list_name_change(ui_selected_names_get()[0], ui_text_anim_name.text)
	refresh_list()
	ui_list_anim_names.select(animation_name_index(new_name))

