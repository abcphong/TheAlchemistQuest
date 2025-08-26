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
	print("[DEBUG] Bắt đầu tạo SaveLoadUI...")
	
	# Instance và hiển thị SaveLoadUI
	# Load scene SaveLoadUI
	var save_ui_scene = preload("res://The_Alchemist_Quest/scenes/player/save_load_ui.tscn")
	if not save_ui_scene:
		print("[ERROR] Không thể load save_load_ui.tscn")
		return
		
	var save_ui_instance = save_ui_scene.instantiate()
	if not save_ui_instance:
		print("[ERROR] Không thể instantiate SaveLoadUI")
		return
		
	print("[DEBUG] SaveLoadUI instance đã tạo thành công")
	
	# Thêm vào SaveUILayer
	$SaveUILayer.add_child(save_ui_instance)
	print("[DEBUG] Đã thêm SaveLoadUI vào SaveUILayer")
	
	# Force hiển thị SaveLoadUI (override visible = false trong _ready)
	save_ui_instance.visible = true
	print("[DEBUG] Đã set visible = true cho SaveLoadUI")
	
	# Ẩn các nút chính
	$VBoxContainer.hide()
	print("[DEBUG] Đã ẩn VBoxContainer")
	
	# Hiển thị SaveUILayer
	$SaveUILayer.show()
	print("[DEBUG] Đã hiển thị SaveUILayer")
	print("[DEBUG] SaveUILayer visible: ", $SaveUILayer.visible)
	print("[DEBUG] SaveUILayer layer: ", $SaveUILayer.layer)
	print("[DEBUG] SaveLoadUI visible: ", save_ui_instance.visible)
	
	# Kết nối signal pressed của nút 'Đóng' trong SaveLoadUI
	var close_button = save_ui_instance.get_node("PanelContainer/MarginContainer/VBoxContainer/CloseButton")
	if close_button:
		close_button.pressed.connect(_on_save_ui_close_pressed)
		print("[DEBUG] Đã kết nối nút Đóng")
	else:
		print("[ERROR] Không tìm thấy nút Đóng")
		
	# Kết nối signal game_loaded từ SaveLoadManager để chuyển scene sau khi load xong
	# Giả sử SaveLoadManager là một node singleton/autoload, hoặc có thể truy cập từ /root
	# Nếu không, cần tìm node SaveLoadManager trong scene
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if not save_load_manager:
		# Nếu không tìm thấy ở /root, thử tìm trong scene tree
		save_load_manager = get_tree().get_root().find_child("SaveLoadManager", true, false)
	if save_load_manager and save_load_manager.has_signal("game_loaded"):
		save_load_manager.connect("game_loaded", Callable(self, "_on_game_loaded"))
		print("[DEBUG] Đã kết nối signal game_loaded")
	else:
		print("[ERROR] Không tìm thấy SaveLoadManager")

func _on_save_ui_close_pressed():
	# Ẩn SaveUILayer
	$SaveUILayer.hide()
	# Xóa tất cả child của SaveUILayer (nếu có)
	for child in $SaveUILayer.get_children():
		$SaveUILayer.remove_child(child)
		child.queue_free()
	# Hiển thị lại các nút chính
	$VBoxContainer.show()

func _on_game_loaded():
	# Chuyển scene đến game sau khi load xong
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/game.tscn")
func _on_tutorial_button_pressed():
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/homepage/tutorial.tscn")  # Hoặc scene hướng dẫn

func _on_exit_pressed():
	get_tree().quit()

func _on_about_us_button_pressed():
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scenes/homepage/about_us.tscn")
