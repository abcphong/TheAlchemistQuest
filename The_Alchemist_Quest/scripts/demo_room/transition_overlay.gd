# TransitionOverlay.gd - Enhanced với Black Screen Transition
extends CanvasLayer

# Tham số hiệu ứng
@export var shake_intensity: float = 30.0
@export var fade_in_duration: float = 0.3
@export var fade_out_duration: float = 0.5
@export var black_fade_duration: float = 0.8  # Thời gian fade to black
@export var white_fade_duration: float = 1.0  # Thời gian fade from black trong scene mới
@export var next_scene_path: String = "res://The_Alchemist_Quest/scenes/Map/game.tscn"
@export var completion_text: String = "ALERT!"

# Post-puzzle dialog settings
@export var dialog_json_path: String = "res://The_Alchemist_Quest/assets/json/demo_AI_dialoge.json"
@export var post_puzzle_sequence_key: String = "Post_Puzzle_Sequence"

# Nodes
@onready var background: ColorRect
@onready var label: Label
@onready var black_screen: ColorRect  # Màn hình đen cho hiệu ứng
@onready var camera: Camera2D
@onready var red_light: AnimatedSprite2D
@onready var dialog_player: DialogPlayer

# Biến trạng thái
var current_shake_intensity: float = 0.0
var original_camera_position: Vector2
var is_dialog_active: bool = false
var is_shaking: bool = false
var should_change_scene_after_dialog: bool = false
var setup_completed: bool = false

func _ready():
	layer = 10  # Đảm bảo layer cao
	
	# Tạo UI overlay
	create_overlay_ui()
	
	# Ẩn overlay ban đầu, nhưng hiện background với độ mờ nhẹ
	visible = true
	background.modulate.a = 0.3
	label.modulate.a = 0.0
	black_screen.modulate.a = 0.0  # Ẩn màn hình đen ban đầu
	
	# Đợi 1 frame để tất cả nodes được setup
	await get_tree().process_frame
	await get_tree().process_frame  # Đợi thêm 1 frame nữa để chắc chắn
	
	setup_scene_references()
	
	# Bắt đầu sequence sau khi setup xong
	if setup_completed:
		start_immediate_sequence()
	else:
		print("❌ Setup failed - falling back to basic alert")
		show_basic_alert()

func setup_scene_references():
	# Setup tất cả references một cách an toàn
	# Setup camera
	camera = find_camera()
	
	if camera:
		original_camera_position = camera.global_position
		print("✅ Camera found:", camera.get_path())
	else:
		print("⚠️ Camera not found - shake effect disabled")
	
	# Setup RedLight
	red_light = get_node_or_null("../RedLight")
	if not red_light:
		red_light = get_tree().get_first_node_in_group("RedLight")
		if not red_light:
			red_light = find_node_by_name(get_tree().root, "RedLight")
	
	if red_light and red_light is AnimatedSprite2D:
		red_light.play("activated")
		print("🔴 RedLight activated")
	
	# Setup DialogPlayer
	setup_dialog_player()
	
	setup_completed = true
	print("✅ Scene setup completed")

func find_camera() -> Camera2D:
	# Tìm Camera2D trong scene tree
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera
	
	# Tìm trong groups
	var cameras = get_tree().get_nodes_in_group("Camera")
	if cameras.size() > 0:
		return cameras[0] as Camera2D
	
	# Tìm recursive
	return find_node_by_class_recursive(get_tree().root, "Camera2D") as Camera2D

func find_node_by_class_recursive(node: Node, target_class: String) -> Node:
	if node.get_class() == target_class:
		return node
	for child in node.get_children():
		var result = find_node_by_class_recursive(child, target_class)
		if result:
			return result
	return null

func find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = find_node_by_name(child, target_name)
		if result:
			return result
	return null

func setup_dialog_player():
	# Tìm DialogPlayer từ nhiều nguồn
	dialog_player = get_node_or_null("../DialogPlayer")
	if not dialog_player:
		dialog_player = get_tree().get_first_node_in_group("DialogPlayer")
	if not dialog_player:
		dialog_player = find_dialog_player_recursive(get_tree().root)
	
	if dialog_player:
		print("✅ DialogPlayer found:", dialog_player.get_path())
		# Kiểm tra xem signal đã connect chưa
		if not dialog_player.is_connected("dialog_finished", _on_dialog_finished):
			dialog_player.connect("dialog_finished", _on_dialog_finished)
			print("📡 Connected to dialog_finished signal")
		else:
			print("📡 dialog_finished signal already connected")
	else:
		print("❌ DialogPlayer not found in alert scene")

func find_dialog_player_recursive(node: Node) -> DialogPlayer:
	if node is DialogPlayer:
		return node
	for child in node.get_children():
		var result = find_dialog_player_recursive(child)
		if result:
			return result
	return null

func create_overlay_ui():
	# Tạo background overlay (màu đỏ cảnh báo)
	background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.8, 0.0, 0.0, 0.6)
	background.modulate.a = 0.0
	add_child(background)
	
	# Tạo container cho label
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center_container)
	
	# Tạo label ALERT
	label = Label.new()
	label.text = completion_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.modulate.a = 0.0
	center_container.add_child(label)
	
	# Tạo màn hình đen cho hiệu ứng transition (layer cao nhất)
	black_screen = ColorRect.new()
	black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_screen.color = Color.BLACK
	black_screen.modulate.a = 0.0
	black_screen.z_index = 100  # Layer cao nhất để che hết
	add_child(black_screen)

# SEQUENCE CHÍNH: Dialog + Rung lắc song song
func start_immediate_sequence():
	print("🚨 Starting immediate alert sequence with dialog")
	
	# Bắt đầu rung lắc NGAY LẬP TỨC và ĐỘC LẬP
	start_continuous_shake()
	
	# Setup dialog song song, không đợi
	if dialog_player and FileAccess.file_exists(dialog_json_path):
		setup_dialog_sequence()
	else:
		print("⚠️ Dialog not available - showing basic alert")
		show_basic_alert()

func setup_dialog_sequence():
	# Setup dialog sequence một cách độc lập
	# Fade in background nhẹ
	var bg_tween = create_tween()
	bg_tween.tween_property(background, "modulate:a", 0.4, fade_in_duration)
	
	# Setup dialog properties
	dialog_player.layer = 25  # Layer cao hơn alert overlay
	dialog_player.visible = true
	dialog_player.set_dialog_file(dialog_json_path)
	
	# Set flags
	is_dialog_active = true
	should_change_scene_after_dialog = true
	
	# Delay một chút để đảm bảo dialog system ready
	await get_tree().create_timer(0.1).timeout
	
	# Trigger dialog
	SignalBus.emit_signal("display_puzzle_dialog", post_puzzle_sequence_key, null)
	print("📢 Post_Puzzle_Sequence dialog started with parallel shake effect")

func show_basic_alert():
	# Hiển thị alert cơ bản nếu không có dialog
	show_alert_text()
	await get_tree().create_timer(3.0).timeout
	call_level_manager_safely()
	await black_screen_transition()

# Rung lắc liên tục - ĐỘC LẬP với dialog
func start_continuous_shake():
	if is_shaking:
		return
	
	if not camera:
		print("⚠️ No camera - shake disabled")
		return
	
	is_shaking = true
	current_shake_intensity = shake_intensity
	print("📳 Started continuous shake with intensity:", shake_intensity)

func stop_shake():
	is_shaking = false
	current_shake_intensity = 0.0
	
	# Khôi phục vị trí camera
	if camera:
		var restore_tween = create_tween()
		restore_tween.tween_property(camera, "global_position", original_camera_position, 0.2)
	
	print("📳 Shake stopped")

# Hiển thị text ALERT
func show_alert_text():
	var text_tween = create_tween()
	text_tween.parallel().tween_property(background, "modulate:a", 0.8, fade_in_duration)
	text_tween.parallel().tween_property(label, "modulate:a", 1.0, fade_in_duration)

# CALLBACK: Khi dialog kết thúc
func _on_dialog_finished():
	print("🔚 Dialog finished - preparing scene transition")
	is_dialog_active = false
	
	if should_change_scene_after_dialog:
		show_alert_text()
		await get_tree().create_timer(1.0).timeout
		stop_shake()
		
		# Gọi LevelManager một cách an toàn
		call_level_manager_safely()
		
		# Bắt đầu hiệu ứng màn hình đen
		await black_screen_transition()

# HÀM MỚI: Hiệu ứng màn hình đen và chuyển scene
func black_screen_transition():
	print("⚫ Starting black screen transition")
	
	# Bước 1: Fade out alert UI trước
	var fade_out_tween = create_tween()
	fade_out_tween.parallel().tween_property(background, "modulate:a", 0.0, fade_out_duration * 0.5)
	fade_out_tween.parallel().tween_property(label, "modulate:a", 0.0, fade_out_duration * 0.5)
	await fade_out_tween.finished
	
	# Bước 2: Fade to black (màn hình đen che hết)
	var black_tween = create_tween()
	black_tween.tween_property(black_screen, "modulate:a", 1.0, black_fade_duration)
	black_tween.tween_callback(print.bind("⚫ Screen fully black"))
	await black_tween.finished
	
	# Bước 3: Đợi một chút trong màn hình đen
	await get_tree().create_timer(0.3).timeout
	
	# Bước 4: Lưu thông tin transition cho scene mới
	prepare_scene_transition_data()
	
	# Bước 5: Chuyển scene
	change_to_next_scene()

# HÀM MỚI: Chuẩn bị dữ liệu cho scene transition
func prepare_scene_transition_data():
	# Lưu thông tin transition vào autoload hoặc scene tree
	# Để scene mới biết cần fade from black
	
	# Sử dụng meta data của scene tree
	get_tree().set_meta("needs_fade_from_black", true)
	get_tree().set_meta("fade_from_black_duration", white_fade_duration)
	
	print("💾 Prepared transition data for next scene")

# HÀM MỚI: Fade from black khi vào scene mới (được gọi từ scene game)
static func handle_scene_fade_in(scene_root: Node):
	var tree = scene_root.get_tree()
	
	# Kiểm tra xem có cần fade from black không
	if not tree.has_meta("needs_fade_from_black"):
		return
	
	var fade_duration = tree.get_meta("fade_from_black_duration", 1.0)
	
	# Tạo overlay đen tạm thời
	var temp_black_overlay = ColorRect.new()
	temp_black_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	temp_black_overlay.color = Color.BLACK
	temp_black_overlay.modulate.a = 1.0
	
	# Tạo CanvasLayer tạm thời với layer cao
	var temp_layer = CanvasLayer.new()
	temp_layer.layer = 100
	temp_layer.add_child(temp_black_overlay)
	scene_root.add_child(temp_layer)
	
	print("⚪ Starting fade from black in new scene")
	
	# Fade from black to transparent
	var fade_tween = scene_root.create_tween()
	fade_tween.tween_property(temp_black_overlay, "modulate:a", 0.0, fade_duration)
	fade_tween.tween_callback(func(): 
		temp_layer.queue_free()
		print("⚪ Fade from black completed")
	)
	
	# Xóa meta data
	tree.remove_meta("needs_fade_from_black")
	tree.remove_meta("fade_from_black_duration")

# HÀM MỚI: Gọi LevelManager một cách an toàn
func call_level_manager_safely():
	# Cách 1: Kiểm tra instance có tồn tại và valid không
	if LevelManager.instance and is_instance_valid(LevelManager.instance):
		if LevelManager.instance.has_method("complete_task_after_alert"):
			LevelManager.instance.complete_task_after_alert()
			print("✅ Successfully called complete_task_after_alert")
			return
		else:
			print("❌ LevelManager exists but missing complete_task_after_alert method")
	else:
		print("❌ LevelManager.instance is null or freed")
	
	# Cách 2: Tìm LevelManager trong scene tree
	var level_manager = get_tree().get_first_node_in_group("LevelManager")
	if not level_manager:
		level_manager = find_node_by_name(get_tree().root, "LevelManager")
	
	if level_manager and level_manager.has_method("complete_task_after_alert"):
		level_manager.complete_task_after_alert()
		print("✅ Found and called LevelManager via scene tree")
		return
	
	# Cách 3: Fallback - không có LevelManager, chỉ chuyển scene
	print("⚠️ No valid LevelManager found - proceeding with scene change only")

func change_to_next_scene():
	print("🎯 Changing to next scene:", next_scene_path)
	
	if FileAccess.file_exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("❌ Next scene not found:", next_scene_path)

# Process rung lắc mỗi frame - CHẠY SONG SONG với dialog
func _process(_delta):
	if is_shaking and camera and current_shake_intensity > 0:
		# Tạo offset ngẫu nhiên cho camera
		var offset = Vector2(
			randf_range(-current_shake_intensity, current_shake_intensity),
			randf_range(-current_shake_intensity, current_shake_intensity)
		)
		
		camera.global_position = original_camera_position + offset

# Input handling
func _input(event):
	if event.is_action_pressed("ui_cancel") and is_dialog_active:
		if dialog_player and dialog_player.in_progress:
			print("🟥 ESC pressed - Force finishing dialog")
			dialog_player.finish()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("turn_off_dialog") and is_dialog_active:
		if dialog_player and dialog_player.in_progress:
			print("🔲 Turn off dialog pressed")
			dialog_player.finish()
		get_viewport().set_input_as_handled()

# DEBUGGING
@export var enable_debug_controls: bool = false

func _unhandled_input(event):
	if not enable_debug_controls:
		return
	
	if event.is_action_pressed("ui_accept"):
		restart_sequence()
	elif event.is_action_pressed("ui_select"):
		await black_screen_transition()
	elif event.is_action_pressed("ui_home"):
		await black_screen_transition()

func restart_sequence():
	# Reset trạng thái
	is_dialog_active = false
	is_shaking = false
	should_change_scene_after_dialog = false
	setup_completed = false
	stop_shake()
	
	# Reset UI
	background.modulate.a = 0.3
	label.modulate.a = 0.0
	black_screen.modulate.a = 0.0
	
	# Restart sequence
	setup_scene_references()
	if setup_completed:
		start_immediate_sequence()

# PUBLIC API
func set_next_scene(path: String):
	if FileAccess.file_exists(path):
		next_scene_path = path
		print("🎯 Next scene updated to:", next_scene_path)
	else:
		print("❌ Invalid scene path:", path)

func trigger_dialog_sequence(dialog_key: String = ""):
	if dialog_key.is_empty():
		dialog_key = post_puzzle_sequence_key
	
	if dialog_player:
		post_puzzle_sequence_key = dialog_key
		start_immediate_sequence()
	else:
		print("❌ Cannot trigger dialog - DialogPlayer not found")

# HÀM MỚI: API để tùy chỉnh thời gian transition
func set_transition_durations(black_fade: float = 0.8, white_fade: float = 1.0):
	black_fade_duration = black_fade
	white_fade_duration = white_fade
	print("⚙️ Transition durations updated: Black=", black_fade, "s, White=", white_fade, "s")
