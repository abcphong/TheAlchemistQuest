extends Node2D

# 🎯 Danh sách PackedScene các puzzle, gán trong Inspector
@export var puzzle_scenes: Array[PackedScene] = []
@export var workbench_id: String = "default_workbench"  # ID duy nhất để nhận dạng workbench này

var current_puzzle_index: int = 0              # Thứ tự puzzle hiện tại
var current_puzzle: Node = null                # Đối tượng puzzle đang hoạt động
var puzzle_completed_flags: Array[bool] = []   # Theo dõi các puzzle đã hoàn thành

func _ready():
	# Kết nối vùng phát hiện người chơi
	$DetectionArea.body_entered.connect(_on_area_2d_body_entered)
	$DetectionArea.body_exited.connect(_on_area_2d_body_exited)

	# Kiểm tra và đảm bảo mảng puzzle_scenes được tải đúng
	print("[DEBUG-WORKBENCH] Kiểm tra mảng puzzle_scenes ban đầu:", puzzle_scenes)
	
	# Nếu mảng trống hoặc kích thước không đúng, thử tải lại từ scene
	if puzzle_scenes.size() < 4:
		print("[DEBUG-WORKBENCH] Tải lại mảng puzzle_scenes từ scene...")
		
		# Tải các scene theo đường dẫn cố định nếu cần
		if puzzle_scenes.size() < 1 or puzzle_scenes[0] == null:
			var intro_scene = load("res://The_Alchemist_Quest/scences/puzzle/intro_room/puzzle_ui_task1.tscn")
			if intro_scene:
				puzzle_scenes.insert(0, intro_scene)
				print("[DEBUG-WORKBENCH] Đã thêm intro_scene")
				
		if puzzle_scenes.size() < 2 or puzzle_scenes[1] == null:
			var storage_scene_1 = load("res://The_Alchemist_Quest/scences/puzzle/storage_room/puzzle_ui_task1.tscn")
			if storage_scene_1:
				if puzzle_scenes.size() < 2:
					puzzle_scenes.append(storage_scene_1)
				else:
					puzzle_scenes[1] = storage_scene_1
				print("[DEBUG-WORKBENCH] Đã thêm storage_scene_1")

		if puzzle_scenes.size() < 3 or puzzle_scenes[2] == null:
			var storage_scene_2 = load("res://The_Alchemist_Quest/scences/puzzle/storage_room/puzzle_ui_task2.tscn")
			if storage_scene_2:
				if puzzle_scenes.size() < 3:
					puzzle_scenes.append(storage_scene_2)
				else:
					puzzle_scenes[2] = storage_scene_2
				print("[DEBUG-WORKBENCH] Đã thêm storage_scene_2 (Task 2.3)")
				
		if puzzle_scenes.size() < 4 or puzzle_scenes[3] == null:
			var security_scene = load("res://The_Alchemist_Quest/scences/puzzle/security_room/puzzle_ui_task1.tscn")
			if security_scene:
				if puzzle_scenes.size() < 4:
					puzzle_scenes.append(security_scene)
				else:
					puzzle_scenes[3] = security_scene
				print("[DEBUG-WORKBENCH] Đã thêm security_scene")

	# Đảm bảo mảng puzzle_scenes được khởi tạo đúng
	if puzzle_scenes.size() == 0:
		print("[DEBUG-WORKBENCH] CẢNH BÁO: Mảng puzzle_scenes trống!")
	else:
		print("[DEBUG-WORKBENCH] Mảng puzzle_scenes có", puzzle_scenes.size(), "phần tử")
		for i in range(puzzle_scenes.size()):
			if puzzle_scenes[i] == null:
				print("[DEBUG-WORKBENCH] CẢNH BÁO: Phần tử", i, "là null!")
			else:
				print("[DEBUG-WORKBENCH] Phần tử", i, ":", puzzle_scenes[i].resource_path)

	# Khởi tạo mảng cờ hoàn thành
	puzzle_completed_flags.resize(puzzle_scenes.size())
	puzzle_completed_flags.fill(false)
	
	print("[DEBUG-WORKBENCH] Đã khởi tạo workbench:", workbench_id, " - với ", puzzle_scenes.size(), " puzzle")
	print("[DEBUG-WORKBENCH] Kiểm tra mảng puzzle_scenes cuối cùng: ", puzzle_scenes)
	print("[DEBUG-WORKBENCH] Số lượng phần tử thực tế: ", puzzle_scenes.size())
	
	# In ra thông tin chi tiết về từng puzzle scene và đảm bảo mảng hoạt động đúng
	for i in range(puzzle_scenes.size()):
		var scene = puzzle_scenes[i]
		if scene != null:
			var resource_path = scene.resource_path
			print("[DEBUG-WORKBENCH] Puzzle", i+1, "- đường dẫn:", resource_path)
	
	# Đăng ký với SaveLoadManager để lưu/tải trạng thái
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)

# Lưu trạng thái của workbench
func save_state() -> Dictionary:
	var state = {
		"workbench_id": workbench_id,
		"current_puzzle_index": current_puzzle_index,
		"puzzle_completed_flags": puzzle_completed_flags.duplicate()
	}
	print("[DEBUG-WORKBENCH] Workbench lưu trạng thái: index=", current_puzzle_index, ", completed=", puzzle_completed_flags)
	return state

# Tải trạng thái của workbench
func load_state(state: Dictionary) -> void:
	if state.has("workbench_id") and state["workbench_id"] == workbench_id:
		current_puzzle_index = state["current_puzzle_index"]
		
		# Khôi phục puzzle_completed_flags
		if state.has("puzzle_completed_flags") and state["puzzle_completed_flags"].size() == puzzle_completed_flags.size():
			for i in range(puzzle_completed_flags.size()):
				puzzle_completed_flags[i] = state["puzzle_completed_flags"][i]
		
		print("[DEBUG-WORKBENCH] Workbench tải trạng thái: index=", current_puzzle_index, ", completed=", puzzle_completed_flags)
		
		# Đóng puzzle hiện tại nếu có
		if current_puzzle != null:
			if is_instance_valid(current_puzzle):
				current_puzzle.queue_free()
			current_puzzle = null

# Lấy ID của workbench
func get_saveable_id() -> String:
	return "workbench_" + workbench_id

func _on_area_2d_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self
		body.can_interact = true  # Đảm bảo đặt can_interact thành true
		print("[DEBUG-WORKBENCH] Người chơi đã vào vùng workbench:", workbench_id)

func _on_area_2d_body_exited(body: Node):
	if body.name == "Player":
		# Chỉ xóa nearby_workbench nếu nó đang tham chiếu đến workbench này
		if body.nearby_workbench == self:
			body.nearby_workbench = null
		body.can_interact = false
		print("[DEBUG-WORKBENCH] Người chơi đã rời khỏi vùng workbench:", workbench_id)

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	print("[DEBUG-WORKBENCH] open_puzzle_ui() được gọi - current_puzzle_index:", current_puzzle_index, "/", puzzle_scenes.size())
	print("[DEBUG-WORKBENCH] Kiểm tra mảng puzzle_scenes: ", puzzle_scenes)
	
	# Kiểm tra nếu đang còn puzzle chưa hoàn thành
	if current_puzzle != null and not puzzle_completed_flags[current_puzzle_index]:
		print("[DEBUG-WORKBENCH] Puzzle hiện tại vẫn đang chạy và chưa hoàn thành")
		return

	# Nếu đã hoàn tất mọi puzzle - sửa lại logic so sánh
	if current_puzzle_index >= puzzle_scenes.size():
		print("[DEBUG-WORKBENCH] Đã hoàn thành tất cả puzzle, không thể mở tiếp")
		# Reset lại current_puzzle_index để có thể chơi lại từ đầu nếu muốn
		# current_puzzle_index = 0
		# print("[DEBUG-WORKBENCH] Đã reset current_puzzle_index về 0")
		return

	print("[DEBUG-WORKBENCH] Chuẩn bị mở puzzle tại index:", current_puzzle_index)
	_spawn_puzzle(current_puzzle_index)

# ⚙️ Tạo và hiển thị puzzle theo chỉ số
func _spawn_puzzle(index: int):
	# Bảo vệ: kiểm tra chỉ số hợp lệ và scene có tồn tại
	if index < 0 or index >= puzzle_scenes.size():
		print("[DEBUG-WORKBENCH] CẢNH BÁO: Không tìm thấy puzzle tại index " + str(index))
		print("[DEBUG-WORKBENCH] Số lượng puzzle hiện có:", puzzle_scenes.size())
		return

	var puzzle_scene: PackedScene = puzzle_scenes[index]
	if puzzle_scene == null:
		print("[DEBUG-WORKBENCH] CẢNH BÁO: PackedScene tại index " + str(index) + " là null")
		return
		
	print("[DEBUG-WORKBENCH] Bắt đầu khởi tạo puzzle từ scene path:", puzzle_scene.resource_path)
	
	# Đặc biệt xử lý cho puzzle thứ 3 (security room)
	if index == 2:
		print("[DEBUG-WORKBENCH] Đang tạo puzzle Security Room (index 2)")
		
	# Dọn puzzle cũ nếu có
	if current_puzzle != null:
		# Kiểm tra xem đối tượng có hợp lệ không trước khi gọi queue_free
		if is_instance_valid(current_puzzle):
			current_puzzle.queue_free()
		current_puzzle = null

	# Tạo mới puzzle
	current_puzzle = puzzle_scene.instantiate()
	if current_puzzle == null:
		print("[DEBUG-WORKBENCH] LỖI: Không thể instantiate puzzle scene!")
		return
		
	print("[DEBUG-WORKBENCH] Puzzle instance tạo thành công, loại:", current_puzzle.get_class(), ", tên:", current_puzzle.name)
	
	get_tree().current_scene.add_child(current_puzzle)
	print("[DEBUG-WORKBENCH] Puzzle đã được thêm vào scene tree")

	# Kết nối tín hiệu nếu puzzle hỗ trợ
	if current_puzzle.has_signal("puzzle_solved"):
		current_puzzle.connect("puzzle_solved", Callable(self, "_on_puzzle_completed"))
		print("[DEBUG-WORKBENCH] Đã kết nối tín hiệu puzzle_solved với puzzle " + str(index + 1))
	else:
		print("[DEBUG-WORKBENCH] CẢNH BÁO: Puzzle không phát tín hiệu 'puzzle_solved'")
		# Liệt kê các tín hiệu có trong puzzle
		for signal_info in current_puzzle.get_signal_list():
			print("[DEBUG-WORKBENCH] Tín hiệu có sẵn:", signal_info.name)

	print("[DEBUG-WORKBENCH] Đã mở puzzle " + str(index + 1))

# ✅ Xử lý khi puzzle hoàn thành
func _on_puzzle_completed():
	print("[DEBUG-WORKBENCH] Puzzle " + str(current_puzzle_index + 1) + " đã hoàn thành")
	
	# Đảm bảo chỉ số hợp lệ trước khi đánh dấu hoàn thành
	if current_puzzle_index >= 0 and current_puzzle_index < puzzle_completed_flags.size():
		puzzle_completed_flags[current_puzzle_index] = true
		print("[DEBUG-WORKBENCH] Đã đánh dấu puzzle", current_puzzle_index, "là hoàn thành")
	else:
		print("[DEBUG-WORKBENCH] LỖI: current_puzzle_index nằm ngoài phạm vi hợp lệ:", current_puzzle_index)
	
	# Tăng chỉ số để chuyển sang puzzle tiếp theo
	current_puzzle_index += 1

	print("[DEBUG-WORKBENCH] Cập nhật current_puzzle_index thành " + str(current_puzzle_index) + "/" + str(puzzle_scenes.size()))
	print("[DEBUG-WORKBENCH] Trạng thái puzzle:", puzzle_completed_flags)
	
	# Kiểm tra nếu đã hoàn thành tất cả puzzle
	if current_puzzle_index >= puzzle_scenes.size():
		print("[DEBUG-WORKBENCH] Đã hoàn thành tất cả", puzzle_scenes.size(), "puzzle!")

	# Dọn dẹp puzzle khỏi màn hình
	if current_puzzle != null:
		# Kiểm tra xem đối tượng có hợp lệ không trước khi gọi queue_free
		if is_instance_valid(current_puzzle):
			current_puzzle.queue_free()
		current_puzzle = null
