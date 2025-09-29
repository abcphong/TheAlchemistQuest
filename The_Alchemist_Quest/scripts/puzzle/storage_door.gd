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
		body.can_interact = true  # Quan trọng: bật tương tác khi vào vùng
		print("👤 Người chơi đã vào vùng tương tác.")

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		body.can_interact = false
		if "nearby_workbench" in body and body.nearby_workbench == self:
			body.nearby_workbench = null
		print("👋 Người chơi đã rời khỏi vùng tương tác.")

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	# Gate: Chỉ cho phép mở Task 1-2 khi Task 1 đã hoàn thành
	if not _is_task1_completed():
		print("⛔ Không thể mở Task 1-2: Task 1 chưa hoàn thành.")
		return

	# Kiểm tra nếu đang còn puzzle chưa hoàn thành
	if current_puzzle != null and not puzzle_completed_flags[current_puzzle_index]:
		print("⚠️ Puzzle hiện tại chưa hoàn thành.")
		return

	# Nếu đã hoàn tất mọi puzzle
	if current_puzzle_index >= puzzle_scenes.size():
		return

	_spawn_puzzle(current_puzzle_index)

# ⚙️ Tạo và hiển thị puzzle theo chỉ số
func _spawn_puzzle(index: int):
	# Bảo vệ: kiểm tra chỉ số hợp lệ và scene có tồn tại
	if index < 0 or index >= puzzle_scenes.size():
		print("❌ Không tìm thấy scene puzzle tại index ", index)
		return

	var puzzle_scene: PackedScene = puzzle_scenes[index]
	if puzzle_scene == null:
		print("❌ PackedScene tại index ", index, " là null.")
		return

	# Dọn puzzle cũ nếu có
	if current_puzzle and is_instance_valid(current_puzzle):
		current_puzzle.queue_free()
		current_puzzle = null

	# Tạo mới puzzle
	current_puzzle = puzzle_scene.instantiate()
	get_tree().current_scene.add_child(current_puzzle)

	# Kết nối tín hiệu nếu puzzle hỗ trợ
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.connect("puzzle_solved", Callable(self, "_on_puzzle_completed"))
	else:
		print("⚠️ Puzzle không phát tín hiệu 'puzzle_solved'.")

	print("🧩 Puzzle ", index + 1, " đã được mở.")

# ✅ Xử lý khi puzzle hoàn thành
func _on_puzzle_completed():
	print("🎉 Puzzle ", current_puzzle_index + 1, " hoàn thành.")
	puzzle_completed_flags[current_puzzle_index] = true
	current_puzzle_index += 1

	# Dọn dẹp puzzle khỏi màn hình
	if current_puzzle and is_instance_valid(current_puzzle):
		current_puzzle = null

	print("▶️ Sẵn sàng mở puzzle tiếp theo khi người chơi nhấn E.")

	# Nếu đã hoàn tất toàn bộ puzzle của cửa kho => coi như cửa đã mở
	if current_puzzle_index >= puzzle_scenes.size():
		_on_storage_door_opened()

# ==== Helpers ====
func _is_task1_completed() -> bool:
	# Chỉ cho phép mở Task 1-2 khi LevelManager đã chuyển sang task kế tiếp (index >= 1)
	if LevelManager and LevelManager.instance:
		return LevelManager.instance.current_task_index >= 1
	# Nếu vì lý do nào đó LevelManager chưa sẵn sàng, coi như chưa hoàn thành
	return false

func _clear_player_inventory():
	# Dựa theo API có sẵn trong PlayerInventory
	if PlayerInventory and PlayerInventory.has_method("clear_inventory"):
		PlayerInventory.clear_inventory()
		print("🧹 Đã clear inventory sau khi mở cửa kho.")
	else:
		print("⚠️ Không tìm thấy PlayerInventory hoặc clear_inventory().")

func _on_storage_door_opened():
	# Hook khi cửa kho chính thức mở (đã giải xong toàn bộ puzzle của cửa)
	_clear_player_inventory()
	# Nếu bạn có logic mở scene/hiệu ứng riêng, có thể gọi ở đây (giữ nguyên phần bạn đã cài rồi).
	# Ví dụ: chuyển scene, bật cờ trong GameManager, v.v.
