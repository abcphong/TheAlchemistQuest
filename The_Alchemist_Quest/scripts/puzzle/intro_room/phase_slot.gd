extends Control

func check_all_slots_filled():
	var parent = get_parent()
	if parent and parent.has_method("check_all_slots_filled"):
		parent.check_all_slots_filled()
