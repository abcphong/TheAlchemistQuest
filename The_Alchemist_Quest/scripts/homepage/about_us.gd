extends Control

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Nhấn ESC → trở về trang homepage
		get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/homepage/homepage.tscn")
