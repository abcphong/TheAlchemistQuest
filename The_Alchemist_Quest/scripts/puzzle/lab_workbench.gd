extends Node2D

# 🎯 Danh sách PackedScene các puzzle, gán trong Inspector
@export var puzzle_scenes: Array[PackedScene] = []
var current_puzzle: Node = null                # Đối tượng puzzle đang hoạt động
var puzzle_completed_flags: Array[bool] = []   # Theo dõi các puzzle đã hoàn thành
var current_task_index: int = 0
var puzzle_ui: CanvasLayer = null
var is_puzzle_open: bool = false
var player = null
func _ready():
	# Kết nối vùng phát hiện người chơi
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

	# Khởi tạo mảng cờ hoàn thành
	puzzle_completed_flags.resize(puzzle_scenes.size())
	puzzle_completed_flags.fill(false)

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		player = body
		body.nearby_workbench = self
		body.can_interact = true 
		print("👤 Người chơi đã vào vùng tương tác.")

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		body.can_interact = false
		body.nearby_workbench = null
		print("👋 Người chơi đã rời khỏi vùng tương tác.")

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	# Kiểm tra nếu đang còn puzzle chưa hoàn thành
	if puzzle_completed_flags[current_task_index]:
		print("⚠️ Puzzle hiện tại chưa hoàn thành.")
		return
	_spawn_puzzle(current_task_index)

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
	if current_puzzle:
		current_puzzle.queue_free()

	# Tạo mới puzzle
	current_puzzle = puzzle_scene.instantiate()
	get_tree().current_scene.add_child(current_puzzle)

	# Kết nối tín hiệu nếu puzzle hỗ trợ
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.connect("puzzle_solved", Callable(self, "_on_puzzle_completed"))
	else:
		print("⚠️ Puzzle không phát tín hiệu 'puzzle_solved'.")

	print("🧩 Puzzle ", index + 1, " đã được mở.")
	
	if current_puzzle.has_method("set_inventory"):
		current_puzzle.set_inventory(PlayerInventory.inventory)

# ✅ Xử lý khi puzzle hoàn thành
func _on_puzzle_completed():
	print("🎉 Puzzle task %d hoàn thành." % (current_task_index + 1))
	puzzle_completed_flags[current_task_index] = true

	if current_puzzle:
		current_puzzle.queue_free()
		current_puzzle = null

	# Phát sự kiện cho LevelManager biết
	EventBus.emit_signal("quest_event", "PUZZLE_%d_COMPLETED" % (current_task_index + 1))

	print("▶️ Sẵn sàng chuyển task hoặc mở puzzle tiếp theo.")
	
func close_puzzle_ui():
	if puzzle_ui:
		if puzzle_ui.has_method("hide_puzzle"):
			puzzle_ui.hide_puzzle()  # This will sync with dialog close
		puzzle_ui.queue_free()
		puzzle_ui = null
		is_puzzle_open = false
		
		# Re-enable main inventory toggle and hide inventory
		if player:
			player.can_open_main_inventory = true
			player.is_in_puzzle_mode = false
			if player.user_interface and player.user_interface.inventory_node.visible:
				player.user_interface.toggle_inventory()
				print("Inventory hidden after puzzle UI closed - Visible:", player.user_interface.inventory_node.visible)
			else:
				print("Inventory already hidden - Visible:", player.user_interface.inventory_node.visible)
		
		print("🧩 Puzzle UI closed - Is Puzzle Open:", is_puzzle_open)

func set_current_puzzle_ui(task_index: int):
	current_task_index = task_index
	print("🧩 Workbench được cập nhật task: ", current_task_index)
