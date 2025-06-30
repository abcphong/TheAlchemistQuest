extends Node2D

# 🎯 Danh sách PackedScene các puzzle, gán trong Inspector
@export var puzzle_scenes: Array[PackedScene] = []

var current_puzzle_index: int = 0              # Thứ tự puzzle hiện tại
var current_puzzle: Node = null                # Đối tượng puzzle đang hoạt động
var puzzle_completed_flags: Array[bool] = []   # Theo dõi các puzzle đã hoàn thành

func _ready():
	# Kết nối vùng phát hiện người chơi
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

	# Khởi tạo mảng cờ hoàn thành
	puzzle_completed_flags.resize(puzzle_scenes.size())
	puzzle_completed_flags.fill(false)

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self
		print("👤 Người chơi đã vào vùng tương tác.")

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		body.can_interact = false
		print("👋 Người chơi đã rời khỏi vùng tương tác.")

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	# Kiểm tra nếu đang còn puzzle chưa hoàn thành
	if current_puzzle != null and not puzzle_completed_flags[current_puzzle_index]:
		print("⚠️ Puzzle hiện tại chưa hoàn thành.")
		return

	# Nếu đã hoàn tất mọi puzzle
	if current_puzzle_index >= puzzle_scenes.size():
		print("✅ Tất cả các puzzle đã hoàn thành.")
		return

	_spawn_puzzle(current_puzzle_index)

# ⚙️ Tạo và hiển thị puzzle theo chỉ số
func _spawn_puzzle(index: int):
	if index < 0 or index >= puzzle_scenes.size():
		print("❌ Không tìm thấy scene puzzle tại index ", index)
		return

	var puzzle_scene: PackedScene = puzzle_scenes[index]
	if puzzle_scene == null:
		print("❌ PackedScene tại index ", index, " là null.")
		return

	if current_puzzle:
		current_puzzle.queue_free()
		current_puzzle = null

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
	print("🎉 Puzzle ", current_puzzle_index + 1, " hoàn thành.")
	puzzle_completed_flags[current_puzzle_index] = true
	current_puzzle_index += 1

	# Dọn dẹp puzzle khỏi màn hình
	if current_puzzle:
		current_puzzle.queue_free()
		current_puzzle = null

	print("▶️ Sẵn sàng mở puzzle tiếp theo khi người chơi nhấn E.")

func show_puzzle_task(index: int):
	if index < 0 or index >= puzzle_scenes.size():
		push_error("❌ Invalid puzzle index!")
		return

	# Instantiate the puzzle scene
	var puzzle_instance = puzzle_scenes[index].instantiate()
	print("✅ Puzzle instance created:", puzzle_instance)

	# Add it to the scene tree
	get_tree().get_root().add_child(puzzle_instance)
	print("📦 Puzzle instance added to scene tree")

	# Try connecting the signal to the fan
	if puzzle_instance.has_signal("fan_activation_requested"):
		var fan_sprite = get_node_or_null("/root/Game/Room1/item/VentilationFan/AnimatedSprite2D")
		if fan_sprite:
			print("💨 Fan sprite found:", fan_sprite)
			puzzle_instance.connect("fan_activation_requested", Callable(fan_sprite, "play").bind("activateda"))
			print("🔗 Signal connected: fan_activation_requested → fan.play('spin')")
		else:
			push_error("❌ Fan sprite not found at /root/Game/Room1/item/VentilationFan/AnimatedSprite2D")
	else:
		push_warning("⚠️ fan_activation_requested signal not found on puzzle scene")
