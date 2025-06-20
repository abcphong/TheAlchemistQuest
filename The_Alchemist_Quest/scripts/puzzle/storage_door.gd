extends "res://The_Alchemist_Quest/scripts/puzzle/generic_door.gd"

# 🎯 Danh sách PackedScene các puzzle, gán trong Inspector
@export var puzzle_scenes: Array[PackedScene] = []
@export var workbench_id: String = "door_workbench"  # ID cho workbench, để tương thích với player.gd

var current_puzzle_index: int = 0              # Thứ tự puzzle hiện tại
var current_puzzle: Node = null                # Đối tượng puzzle đang hoạt động
var puzzle_completed_flags: Array[bool] = []   # Theo dõi các puzzle đã hoàn thành

func _ready():
	# Gọi _ready của lớp cha
	super._ready()
	
	# Kết nối vùng phát hiện người chơi
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

	# Khởi tạo mảng cờ hoàn thành
	puzzle_completed_flags.resize(puzzle_scenes.size())
	puzzle_completed_flags.fill(false)

# Ghi đè lưu trạng thái của cửa
func save_state() -> Dictionary:
	# Lấy trạng thái cơ bản từ lớp cha
	var state = super.save_state()
	
	# Thêm thông tin về puzzle
	state["current_puzzle_index"] = current_puzzle_index
	state["puzzle_completed_flags"] = puzzle_completed_flags.duplicate()
	
	print("[SaveSystem] Door '" + door_id + "' lưu trạng thái: index=" + str(current_puzzle_index) + ", completed=" + str(puzzle_completed_flags) + ", open=" + str(is_door_open))
	return state

# Ghi đè tải trạng thái của cửa
func load_state(state: Dictionary) -> void:
	# Tải trạng thái cơ bản từ lớp cha
	super.load_state(state)
	
	if state.has("door_id") and state["door_id"] == door_id:
		if state.has("current_puzzle_index"):
			current_puzzle_index = state["current_puzzle_index"]
		
		# Khôi phục puzzle_completed_flags
		if state.has("puzzle_completed_flags") and state["puzzle_completed_flags"].size() == puzzle_completed_flags.size():
			for i in range(puzzle_completed_flags.size()):
				puzzle_completed_flags[i] = state["puzzle_completed_flags"][i]
		
		print("[SaveSystem] Door '" + door_id + "' tải trạng thái: index=" + str(current_puzzle_index) + ", completed=" + str(puzzle_completed_flags) + ", open=" + str(is_door_open))
		
		# Đóng puzzle hiện tại nếu có
		if current_puzzle != null:
			if is_instance_valid(current_puzzle):
				current_puzzle.queue_free()
			current_puzzle = null

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self
		body.can_interact = true  # Đảm bảo đặt can_interact thành true

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		# Nếu người chơi đang tương tác với cửa này, đặt lại tham chiếu
		if body.nearby_workbench == self:
			body.nearby_workbench = null
		body.can_interact = false

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	# Kiểm tra nếu đang còn puzzle chưa hoàn thành
	if current_puzzle != null and not puzzle_completed_flags[current_puzzle_index]:
		return

	# Nếu đã hoàn tất mọi puzzle
	if current_puzzle_index >= puzzle_scenes.size():
		# Nếu đã giải xong tất cả puzzle, mở cửa
		if all_puzzles_completed() and not is_door_open:
			open_door()
		return

	_spawn_puzzle(current_puzzle_index)

# Kiểm tra xem đã hoàn thành tất cả các câu đố chưa
func all_puzzles_completed() -> bool:
	for completed in puzzle_completed_flags:
		if not completed:
			return false
	return puzzle_completed_flags.size() > 0

# Hàm mở cửa
func open_door():
	is_door_open = true
	update_door_state(true)
	print("[Door] Door '" + door_id + "' đã được mở")

# Cập nhật trạng thái cửa (có thể overridden bởi lớp con)
func update_door_state(is_open: bool):
	# Chỉ xử lý logic, không thay đổi texture
	# Lớp con có thể override để xử lý chi tiết hơn
	pass

# ⚙️ Tạo và hiển thị puzzle theo chỉ số
func _spawn_puzzle(index: int):
	# Bảo vệ: kiểm tra chỉ số hợp lệ và scene có tồn tại
	if index < 0 or index >= puzzle_scenes.size():
		print("[Puzzle] Không tìm thấy puzzle tại index " + str(index))
		return

	var puzzle_scene: PackedScene = puzzle_scenes[index]
	if puzzle_scene == null:
		print("[Puzzle] PackedScene tại index " + str(index) + " là null")
		return

	# Dọn puzzle cũ nếu có
	if current_puzzle and is_instance_valid(current_puzzle):
		current_puzzle.queue_free()
		current_puzzle = null

	# Kiểm tra xem có puzzle khác đang mở không (từ các workbench/cửa khác)
	var active_puzzles = []
	for node in get_tree().current_scene.get_children():
		if "PuzzleUI" in node.name or "puzzle_ui" in node.name:
			active_puzzles.append(node)
			
	if active_puzzles.size() > 0:
		print("[Puzzle] Đã có puzzle khác đang mở, không mở thêm puzzle mới")
		return

	# Tạo mới puzzle
	current_puzzle = puzzle_scene.instantiate()
	get_tree().current_scene.add_child(current_puzzle)

	# Kết nối tín hiệu nếu puzzle hỗ trợ
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.connect("puzzle_solved", Callable(self, "_on_puzzle_completed"))
	else:
		print("[Puzzle] Puzzle không phát tín hiệu 'puzzle_solved'")

	print("[Puzzle] Door '" + door_id + "' mở puzzle " + str(index + 1))

# ✅ Xử lý khi puzzle hoàn thành
func _on_puzzle_completed():
	print("[Puzzle] Door '" + door_id + "' hoàn thành puzzle " + str(current_puzzle_index + 1))
	puzzle_completed_flags[current_puzzle_index] = true
	current_puzzle_index += 1

	# Nếu đã hoàn thành tất cả puzzle, mở cửa
	if all_puzzles_completed():
		open_door()

	# Dọn dẹp puzzle khỏi màn hình
	if current_puzzle and is_instance_valid(current_puzzle):
		current_puzzle.queue_free()
		current_puzzle = null
