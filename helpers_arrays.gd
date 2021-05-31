extends Node

static func array_find_value(arr, value_to_find) -> int:
	for i in range(0, arr.size()):
		if arr[i] == value_to_find:
			return i
	return -1
