extends Node2D

# ID duy nhất của cửa
@export var door_id: String = "storage_door_main"
@export var puzzle_scenes: Array[PackedScene] = []
@export var storage_room_scene: String = "res://The_Alchemist_Quest/scences/storage_room_level.tscn"
@export var workbench_id: String = "door_workbench"  # ID cho workbench, để tương thích với player.gd

# Biến theo dõi trạng thái
var is_door_open: bool = false
var has_been_entered: bool = false  # Biến mới để theo dõi trạng thái đã vào phòng
var current_puzzle_index: int = 0              # Thứ tự puzzle hiện tại
var current_puzzle: Node = null                # Đối tượng puzzle đang hoạt động
var puzzle_completed_flags: Array[bool] = []   # Theo dõi các puzzle đã hoàn thành
var interaction_prompt: Node = null            # Thông báo tương tác

func _ready():
	# Kết nối vùng phát hiện người chơi
	$DetectionArea.body_entered.connect(_on_detection_area_body_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_body_exited)

	# Khởi tạo mảng cờ hoàn thành
	puzzle_completed_flags.resize(puzzle_scenes.size())
	puzzle_completed_flags.fill(false)
	
	# Tìm thông báo tương tác nếu có
	interaction_prompt = get_node_or_null("InteractionPrompt")
	if interaction_prompt:
		interaction_prompt.visible = false
		
	# Thêm cửa vào nhóm StorageDoors để dễ tìm trong GameManager
	add_to_group("StorageDoors")
	
	# Đăng ký với SaveLoadManager
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		# Tải trạng thái từ SaveLoadManager nếu có
		var saved_state = save_load_manager.get_door_state(door_id)
		if saved_state and not saved_state.is_empty():
			load_state(saved_state)
			print("[StorageDoor] Đã tải trạng thái cửa từ SaveLoadManager: " + door_id)

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		body.nearby_workbench = self
		body.can_interact = true  # Đảm bảo đặt can_interact thành true
		
		# Hiển thị thông báo tương tác nếu cửa đã mở
		if interaction_prompt and is_door_open:
			interaction_prompt.visible = true

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		# Nếu người chơi đang tương tác với cửa này, đặt lại tham chiếu
		if body.nearby_workbench == self:
			body.nearby_workbench = null
		body.can_interact = false
		
		# Ẩn thông báo tương tác
		if interaction_prompt:
			interaction_prompt.visible = false

# 🧩 Hàm được gọi từ Player khi nhấn E
func open_puzzle_ui():
	# Kiểm tra nếu đã từng vào phòng hoặc cửa đã mở khóa, cho phép người chơi vào phòng
	if has_been_entered or is_door_open:
		enter_room()
		return

	# Kiểm tra nếu đang còn puzzle chưa hoàn thành
	if current_puzzle != null and not puzzle_completed_flags[current_puzzle_index]:
		return

	# Nếu đã hoàn tất mọi puzzle
	if current_puzzle_index >= puzzle_scenes.size():
		return

	_spawn_puzzle(current_puzzle_index)

# Kiểm tra xem đã hoàn thành tất cả các câu đố chưa
func all_puzzles_completed() -> bool:
	# Nếu đã từng vào phòng storage, luôn cho phép vào mà không cần kiểm tra puzzle
	if has_been_entered:
		return true
		
	# Kiểm tra các puzzle nếu chưa từng vào phòng
	for completed in puzzle_completed_flags:
		if not completed:
			return false
	return puzzle_completed_flags.size() > 0

# Hàm mở khóa cửa
func open_door():
	is_door_open = true
	print("[Door] Door '" + door_id + "' đã được mở khóa")
	
	# Hiển thị thông báo tương tác nếu người chơi đang ở gần
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.nearby_workbench == self and interaction_prompt:
		interaction_prompt.visible = true

# Hàm vào phòng (được gọi khi nhấn E và cửa đã mở khóa)
func enter_room():
	print("[Door] Người chơi đang vào phòng lưu trữ")
	
	# Đánh dấu đã vào phòng storage
	has_been_entered = true
	is_door_open = true  # Đảm bảo cửa được đánh dấu là đã mở
	
	# Lưu vị trí người chơi khi vào phòng lưu trữ
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			var player_position = player.global_position
			# Lưu vị trí vào cả hai biến để đảm bảo tương thích với cả hai cách
			game_manager.storage_door_entry_position = player_position
			# Thêm dòng này để sử dụng hàm save_player_position
			game_manager.save_player_position(player_position, "storage_door_entry")
			print("[StorageDoor] Đã lưu vị trí vào phòng:", player_position)
	
	# Lưu trạng thái tạm thời trước khi chuyển cảnh
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		# Lưu trạng thái cửa trước
		save_load_manager.save_door_state(door_id, save_state())
		# Sau đó lưu trạng thái tạm thời
		save_load_manager.persist_state_for_transition()
		print("[StorageDoor] Đã lưu trạng thái tạm thời trước khi chuyển cảnh")
	
	# Chuyển sang phòng lưu trữ
	get_tree().change_scene_to_file(storage_room_scene)

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

	# Nếu đã hoàn thành tất cả puzzle, mở khóa cửa (không tự động vào phòng)
	if all_puzzles_completed():
		open_door()

	# Dọn dẹp puzzle khỏi màn hình
	if current_puzzle and is_instance_valid(current_puzzle):
		current_puzzle.queue_free()
		current_puzzle = null 
		
	# Lưu trạng thái cửa sau khi hoàn thành puzzle
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		save_load_manager.save_door_state(door_id, save_state())
		print("[StorageDoor] Đã lưu trạng thái cửa sau khi hoàn thành puzzle")

# Hàm lưu trạng thái cửa
func save_state() -> Dictionary:
	var state = {
		"door_id": door_id,
		"is_door_open": is_door_open,
		"has_been_entered": has_been_entered,
		"puzzle_completed_flags": puzzle_completed_flags,
		"current_puzzle_index": current_puzzle_index
	}
	print("[SaveSystem] Storage Door '" + door_id + "' lưu trạng thái đã vào: " + str(has_been_entered))
	return state

# Hàm tải trạng thái cửa
func load_state(state: Dictionary) -> void:
	if state.has("door_id") and state["door_id"] == door_id:
		if state.has("is_door_open"):
			is_door_open = state["is_door_open"]
		
		if state.has("has_been_entered"):
			has_been_entered = state["has_been_entered"]
			print("[SaveSystem] Storage Door '" + door_id + "' tải trạng thái đã vào: " + str(has_been_entered))
		
		if state.has("puzzle_completed_flags"):
			# Đảm bảo kích thước mảng phù hợp
			if state["puzzle_completed_flags"].size() == puzzle_completed_flags.size():
				# Chuyển đổi từng phần tử từ mảng thông thường sang mảng bool
				for i in range(puzzle_completed_flags.size()):
					puzzle_completed_flags[i] = bool(state["puzzle_completed_flags"][i])
				print("[SaveSystem] Storage Door '" + door_id + "' đã tải trạng thái puzzle_completed_flags")
			
		if state.has("current_puzzle_index"):
			current_puzzle_index = state["current_puzzle_index"]

# Trả về ID của cửa để sử dụng với SaveLoadManager
func get_door_id() -> String:
	return door_id 
