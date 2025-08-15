extends Control

func _ready():
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_button_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_button_pressed)
	$VBoxContainer/TutorialButton.pressed.connect(_on_tutorial_button_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)

func _on_new_game_button_pressed():
#Chuyển cảnh
	var tween := create_tween()
	$FadeRect.visible = true
	$FadeRect.modulate.a = 0.0

	tween.tween_property($FadeRect, "modulate:a", 1.0, 0.8)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_load_game_scene"))

func _load_game_scene():
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/game.tscn")
	
func _on_continue_button_pressed():
	print("Tiếp tục game (tùy chỉnh theo cách bạn lưu game)")
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/game.tscn") # chỉnh ở đây để load phần save slot vào

func _on_tutorial_button_pressed():
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/homepage/tutorial.tscn")  # Hoặc scene hướng dẫn

func _on_exit_pressed():
	get_tree().quit()

func _on_about_us_button_pressed():
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/homepage/about_us.tscn")
