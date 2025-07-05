extends Node2D

# 🎯 Danh sách PackedScene các puzzle, gán trong Inspector
@export var puzzle_scenes: Array[PackedScene] = []
@export var workbench_id: String = "ventilation_control_system"

var current_puzzle_index: int = 0              # Thứ tự puzzle hiện tại
var current_puzzle: Node = null                # Đối tượng puzzle đang hoạt động
var puzzle_completed_flags: Array[bool] = []   # Theo dõi các puzzle đã hoàn thành
var is_ventilation_fixed: bool = false         # Trạng thái đã sửa xong hệ thống thông gió

func _ready():
	# Kết nối vùng phát hiện người chơi
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

	# Khởi tạo mảng cờ hoàn thành
	puzzle_completed_flags.resize(puzzle_scenes.size())
	puzzle_completed_flags.fill(false)
	
	# Đăng ký với SaveLoadManager
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)
		print("[VentilationSystem] Đã đăng ký với SaveLoadManager")
	
	# Nếu hệ thống đã được sửa, cập nhật trạng thái quạt và thanh máu
	if is_ventilation_fixed:
		_apply_ventilation_fixed_state()

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self
		body.can_interact = true
		print("👤 Người chơi đã vào vùng tương tác.")

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		body.nearby_workbench = null
		body.can_interact = false
		print("👋 Người chơi đã rời khỏi vùng tương tác.")

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	# Nếu hệ thống đã được sửa, không mở puzzle nữa
	if is_ventilation_fixed:
		print("✅ Hệ thống thông gió đã được sửa.")
		return
		
	# Luôn mở puzzle 0 (puzzle 3) khi nhấn E
	_spawn_puzzle(0)

# ⚙️ Tạo và hiển thị puzzle theo chỉ số
func _spawn_puzzle(index: int):
	if index < 0 or index >= puzzle_scenes.size():
		print("❌ Không tìm thấy scene puzzle tại index ", index)
		return

	var puzzle_scene: PackedScene = puzzle_scenes[index]
	if puzzle_scene == null:
		print("❌ PackedScene tại index ", index, " là null.")
		return

	# Dọn dẹp puzzle hiện tại nếu có
	if current_puzzle and is_instance_valid(current_puzzle):
		var temp_puzzle = current_puzzle
		current_puzzle = null
		temp_puzzle.queue_free()
		# Đợi một khung hình để đảm bảo đối tượng đã được giải phóng
		await get_tree().process_frame

	current_puzzle = puzzle_scene.instantiate()
	get_tree().current_scene.add_child(current_puzzle)

	# Kết nối tín hiệu puzzle_solved
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.connect("puzzle_solved", Callable(self, "_on_puzzle_completed"))
	else:
		print("⚠️ Puzzle không phát tín hiệu 'puzzle_solved'.")

	# ✅ Kết nối fan_activation_requested (NEW!)
	if current_puzzle.has_signal("fan_activation_requested"):
		var fan_sprite = get_node_or_null("/root/Game/Room1/item/VentilationFan")
		if fan_sprite:
			print("💨 Fan sprite found:", fan_sprite)
			current_puzzle.connect("fan_activation_requested", Callable(fan_sprite, "play").bind("activated"))
			print("🔗 Signal connected: fan_activation_requested → fan.play('activated')")
		else:
			push_error("❌ Fan sprite not found at /root/Game/Room1/item/VentilationFan")
	else:
		push_warning("⚠️ fan_activation_requested signal not found on puzzle scene")

	print("🧩 Puzzle ", index + 1, " đã được mở.")

# ✅ Xử lý khi puzzle hoàn thành
func _on_puzzle_completed():
	print("🎉 Puzzle hoàn thành.")
	
	# Đánh dấu hệ thống thông gió đã được sửa
	is_ventilation_fixed = true
	
	# Áp dụng trạng thái đã sửa
	_apply_ventilation_fixed_state()
	
	# Không tăng current_puzzle_index để có thể mở lại puzzle
	# puzzle_completed_flags[current_puzzle_index] = true
	# current_puzzle_index += 1

	# Dọn dẹp puzzle khỏi màn hình - kiểm tra nếu vẫn còn hợp lệ
	if current_puzzle and is_instance_valid(current_puzzle):
		# Đặt current_puzzle = null trước để tránh gọi queue_free() nhiều lần
		var temp_puzzle = current_puzzle
		current_puzzle = null
		temp_puzzle.queue_free()

	print("▶️ Hệ thống thông gió đã được sửa.")

# Áp dụng trạng thái khi hệ thống thông gió đã được sửa
func _apply_ventilation_fixed_state():
	# Kích hoạt quạt thông gió
	var fan_sprite = get_node_or_null("/root/Game/Room1/item/VentilationFan")
	if fan_sprite and fan_sprite.has_method("play"):
		fan_sprite.play("activated")
		print("💨 Đã kích hoạt quạt thông gió")
	
	# Tắt thanh máu
	var health_bar = get_node_or_null("/root/Game/UI/HealthBar")
	if health_bar:
		if health_bar.has_method("hide_health_bar"):
			health_bar.hide_health_bar()
		else:
			if health_bar.HealthTimer:
				health_bar.HealthTimer.stop()
			if health_bar.healthbar:
				health_bar.healthbar.hide()
		print("🛑 Đã tắt thanh máu")

func show_puzzle_task(index: int = 0):
	# Nếu hệ thống đã được sửa, không mở puzzle nữa
	if is_ventilation_fixed:
		print("✅ Hệ thống thông gió đã được sửa.")
		return
		
	# Luôn sử dụng index 0 (puzzle 3)
	index = 0
	
	if index < 0 or index >= puzzle_scenes.size():
		push_error("❌ Invalid puzzle index!")
		return

	# Kiểm tra và dọn dẹp puzzle hiện tại nếu có
	if current_puzzle and is_instance_valid(current_puzzle):
		var temp_puzzle = current_puzzle
		current_puzzle = null
		temp_puzzle.queue_free()
		# Đợi một khung hình để đảm bảo đối tượng đã được giải phóng
		await get_tree().process_frame

	# Instantiate the puzzle scene
	var puzzle_instance = puzzle_scenes[index].instantiate()
	print("✅ Puzzle instance created:", puzzle_instance)
	
	# Lưu tham chiếu
	current_puzzle = puzzle_instance

	# Add it to the scene tree
	get_tree().get_root().add_child(puzzle_instance)
	print("📦 Puzzle instance added to scene tree")

	# Try connecting the signal to the fan
	if puzzle_instance.has_signal("fan_activation_requested"):
		var fan_sprite = get_node_or_null("/root/Game/Room1/item/VentilationFan")
		if fan_sprite:
			print("💨 Fan sprite found:", fan_sprite)
			puzzle_instance.connect("fan_activation_requested", Callable(fan_sprite, "play").bind("activated"))
			print("🔗 Signal connected: fan_activation_requested → fan.play('activated')")
		else:
			push_error("❌ Fan sprite not found at /root/Game/Room1/item/VentilationFan")
	else:
		push_warning("⚠️ fan_activation_requested signal not found on puzzle scene")

# Lấy ID để sử dụng với SaveLoadManager
func get_saveable_id() -> String:
	return "ventilation_system_" + workbench_id

# Lưu trạng thái
func save_state() -> Dictionary:
	var state = {
		"is_ventilation_fixed": is_ventilation_fixed,
		"puzzle_completed_flags": puzzle_completed_flags.duplicate(),
		"current_puzzle_index": current_puzzle_index
	}
	
	# Lưu trạng thái vào GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.ventilation_system_state = {
			"is_ventilation_fixed": is_ventilation_fixed
		}
		
	print("[SaveSystem] Ventilation system lưu trạng thái: fixed=", is_ventilation_fixed)
	return state

# Tải trạng thái
func load_state(state: Dictionary) -> void:
	# Kiểm tra trạng thái từ GameManager trước
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.get("ventilation_system_state") != null:
		if game_manager.ventilation_system_state.has("is_ventilation_fixed"):
			is_ventilation_fixed = game_manager.ventilation_system_state["is_ventilation_fixed"]
			print("[SaveSystem] Ventilation system tải trạng thái từ GameManager: fixed=", is_ventilation_fixed)
	
	# Nếu không có trong GameManager, sử dụng trạng thái từ tham số
	elif state.has("is_ventilation_fixed"):
		is_ventilation_fixed = state["is_ventilation_fixed"]
		print("[SaveSystem] Ventilation system tải trạng thái từ save file: fixed=", is_ventilation_fixed)
		
	# Nếu hệ thống đã được sửa, áp dụng trạng thái
	if is_ventilation_fixed:
		_apply_ventilation_fixed_state()
	
	if state.has("puzzle_completed_flags"):
		# Đảm bảo kích thước mảng phù hợp
		if state["puzzle_completed_flags"].size() == puzzle_completed_flags.size():
			for i in range(puzzle_completed_flags.size()):
				puzzle_completed_flags[i] = bool(state["puzzle_completed_flags"][i])
	
	if state.has("current_puzzle_index"):
		current_puzzle_index = state["current_puzzle_index"]
