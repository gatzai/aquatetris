extends Node2D

class_name BorderLine

func is_line_full(max_count):
	return max_count == get_child_count()

func is_line_has_medium(medium: Shared.TetrominoMedium):
	for child in get_children():
		if child.medium == medium:
			return true
	return false
