extends Node

# Số lượng slot lưu game tối đa
const MAX_SAVE_SLOTS = 3

# Đường dẫn đến file lưu trò chơi
const SAVE_FILE_PATH_TEMPLATE = "user://game_save_{0}.dat" # {0} sẽ được thay thế bằng số slot

# Signal để thông báo khi load game hoàn tất
signal game_loaded

# Dữ liệu sẽ được lưu
var current_game_state = {}
var current_slot = 0

# Danh sách các đối tượng có thể lưu trạng thái
var saveable_objects = {}

# Bộ nhớ đệm để lưu trạng thái tạm thời giữa các lần chuyển cảnh
var scene_transition_cache = {}

# Bộ nhớ đệm để lưu trạng thái của các cửa
var door_states = {}

func _ready():
	print("SaveLoadManager is ready")

# Đăng ký đối tượng có thể lưu trạng thái
func register_saveable_object(object: Node) -> void:
	if object.has_method("get_saveable_id") and object.has_method("save_state") and object.has_method("load_state"):
		var object_id = object.get_saveable_id()
		saveable_objects[object_id] = object
		print("[SaveSystem] Đăng ký đối tượng: " + object_id)
		
		# Kiểm tra xem có trạng thái đã lưu trong cache không
		if scene_transition_cache.has(object_id):
			print("[SaveSystem] Phát hiện trạng thái trong cache cho: " + object_id)
			object.load_state(scene_transition_cache[object_id])
			print("[SaveSystem] Đã khôi phục trạng thái từ cache cho: " + object_id)
	else:
		print("[SaveSystem] Đối tượng không hỗ trợ giao diện lưu/tải.")

# Hủy đăng ký đối tượng
func unregister_saveable_object(object: Node) -> void:
	if object.has_method("get_saveable_id"):
		var object_id = object.get_saveable_id()
		if saveable_objects.has(object_id):
			saveable_objects.erase(object_id)

# Lấy đường dẫn file lưu cho slot cụ thể
func get_save_file_path(slot: int) -> String:
	return SAVE_FILE_PATH_TEMPLATE.format([slot])

# Lưu trò chơi
func save_game(slot: int, save_name: String = "") -> bool:
	print("[SaveSystem] Đang lưu game vào slot " + str(slot) + "...")
	
	# Kiểm tra slot hợp lệ
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		print("[SaveSystem] Slot không hợp lệ: " + str(slot))
		return false
	
	# Tạo deep copy của inventory để xử lý
	var inventory_data = {}
	for slot_index in PlayerInventory.inventory:
		var item = PlayerInventory.inventory[slot_index]
		# Chuyển đổi key thành string để an toàn cho JSON
		var key_str = str(slot_index)
		if item != null:
			inventory_data[key_str] = item.duplicate() # Deep copy mảng
		else:
			inventory_data[key_str] = null
	
	# Tạo deep copy của hotbar
	var hotbar_data = {}
	for slot_index in PlayerInventory.hotbar:
		var item = PlayerInventory.hotbar[slot_index]
		# Chuyển đổi key thành string để an toàn cho JSON
		var key_str = str(slot_index)
		if item != null:
			hotbar_data[key_str] = item.duplicate() # Deep copy mảng
		else:
			hotbar_data[key_str] = null
	
	# Log inventory và hotbar khi lưu (chỉ debug)
	print("[SaveSystem] Inventory được lưu: " + str(inventory_data))
	print("[SaveSystem] Hotbar được lưu: " + str(hotbar_data))
	
	# Nếu không cung cấp tên, tạo tên mặc định
	if save_name.is_empty():
		save_name = "Bản lưu #" + str(slot + 1)
	
	# Lưu trạng thái của các đối tượng đã đăng ký
	var objects_state = {}
	for object_id in saveable_objects:
		var object = saveable_objects[object_id]
		if is_instance_valid(object) and object.has_method("save_state"):
			objects_state[object_id] = object.save_state()
			print("[SaveSystem] Lưu trạng thái: " + object_id)
	
	# Lấy trạng thái thanh máu từ GameManager
	var health_state = {}
	var ventilation_system_state = {}
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		health_state = game_manager.health_state
		ventilation_system_state = game_manager.ventilation_system_state
	
	# Cập nhật trạng thái cửa từ các cửa trong scene hiện tại
	# Kiểm tra cả hai nhóm: StorageDoors và SecurityDoors
	var all_doors = []
	all_doors.append_array(get_tree().get_nodes_in_group("StorageDoors"))
	all_doors.append_array(get_tree().get_nodes_in_group("SecurityDoors"))
	
	for door in all_doors:
		if door.has_method("get_door_id") and door.has_method("save_state"):
			var door_id = door.get_door_id()
			var door_state = door.save_state()
			door_states[door_id] = door_state
			print("[SaveSystem] Lưu trạng thái cửa: " + door_id)
	
	# Tạo dictionary chứa tất cả dữ liệu cần lưu
	var save_data = {
		# Thông tin bản lưu
		"save_name": save_name,
		"save_time": Time.get_datetime_string_from_system(),
		# Player data
		"player_position_x": get_player_position().x,
		"player_position_y": get_player_position().y,
		"player_health": health_state,
		# Inventory data
		"inventory": inventory_data,
		"hotbar": hotbar_data,
		# Checkpoint data
		"checkpoint_position_x": CheckpointManager.current_checkpoint_position.x,
		"checkpoint_position_y": CheckpointManager.current_checkpoint_position.y,
		# Trạng thái các đối tượng trong game
		"objects_state": objects_state,
		# Trạng thái hệ thống thông gió
		"ventilation_system_state": ventilation_system_state,
		# Trạng thái các cửa
		"door_states": door_states,
	}
	
	current_game_state = save_data
	current_slot = slot
	
	# Ghi file
	var file_path = get_save_file_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("[SaveSystem] Đã lưu game thành công vào slot " + str(slot))
		return true
	else:
		print("[SaveSystem] Không thể lưu game vào slot " + str(slot))
		return false

# Tải trò chơi
func load_game(slot: int) -> bool:
	print("[SaveSystem] Đang tải game từ slot " + str(slot) + "...")
	
	# Kiểm tra slot hợp lệ
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		print("[SaveSystem] Slot không hợp lệ: " + str(slot))
		return false
	
	var file_path = get_save_file_path(slot)
	if !FileAccess.file_exists(file_path):
		print("[SaveSystem] Không tìm thấy file lưu game ở slot " + str(slot))
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if !file:
		print("[SaveSystem] Không thể mở file lưu game ở slot " + str(slot))
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json_result = JSON.parse_string(json_string)
	if json_result == null:
		print("[SaveSystem] Không thể parse file lưu game!")
		return false
		
	# Lưu vào biến current_game_state
	current_game_state = json_result
	current_slot = slot
	
	# Áp dụng dữ liệu đã tải
	apply_loaded_data(json_result)
	
	print("[SaveSystem] Đã tải game thành công từ slot " + str(slot))
	emit_signal("game_loaded")
	return true

# Áp dụng dữ liệu sau khi tải
func apply_loaded_data(data):
	# Áp dụng dữ liệu người chơi
	var player_pos = Vector2(float(data["player_position_x"]), float(data["player_position_y"]))
	set_player_position(player_pos)

	# Áp dụng dữ liệu thanh máu vào GameManager
	if data.has("player_health"):
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.health_state = data["player_health"]
	
	# Áp dụng trạng thái hệ thống thông gió
	if data.has("ventilation_system_state"):
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.ventilation_system_state = data["ventilation_system_state"]
			print("[SaveSystem] Đã tải trạng thái hệ thống thông gió: ", game_manager.ventilation_system_state)

	# RESET HOÀN TOÀN INVENTORY VÀ HOTBAR
	print("[SaveSystem] Khởi tạo lại inventory và hotbar...")
	
	# Khởi tạo lại inventory trống
	PlayerInventory.inventory = {}
	for i in range(PlayerInventory.NUM_INVENTORY_SLOTS):
		PlayerInventory.inventory[i] = [null, 0]
	
	# Khởi tạo lại hotbar trống
	PlayerInventory.hotbar = {}
	for i in range(PlayerInventory.NUM_HOTBARS_SLOTS):
		PlayerInventory.hotbar[i] = ["", 0]
	
	# Áp dụng dữ liệu inventory từ bản lưu
	print("[SaveSystem] Đang khôi phục inventory...")
	var saved_inventory = data["inventory"]
	for key_str in saved_inventory:
		var key = int(key_str) # Chuyển đổi key từ string thành int
		var value = saved_inventory[key_str]
		if value != null:
			PlayerInventory.inventory[key] = value
	
	# Áp dụng dữ liệu hotbar từ bản lưu
	print("[SaveSystem] Đang khôi phục hotbar...")
	var saved_hotbar = data["hotbar"]
	for key_str in saved_hotbar:
		var key = int(key_str) # Chuyển đổi key từ string thành int
		var value = saved_hotbar[key_str]
		if value != null:
			PlayerInventory.hotbar[key] = value
	
	# Log inventory và hotbar khi tải (chỉ debug)
	print("[SaveSystem] Inventory sau khi tải: " + str(PlayerInventory.inventory))
	print("[SaveSystem] Hotbar sau khi tải: " + str(PlayerInventory.hotbar))
	
	# Cập nhật UI inventory
	update_inventory_ui()
	
	# Cập nhật vị trí checkpoint
	var checkpoint_pos = Vector2(float(data["checkpoint_position_x"]), float(data["checkpoint_position_y"]))
	CheckpointManager.current_checkpoint_position = checkpoint_pos
	
	# Khôi phục trạng thái các đối tượng
	print("[SaveSystem] Đang khôi phục trạng thái các đối tượng...")
	if data.has("objects_state"):
		var objects_state = data["objects_state"]
		for object_id in objects_state:
			if saveable_objects.has(object_id):
				var object = saveable_objects[object_id]
				if is_instance_valid(object) and object.has_method("load_state"):
					object.load_state(objects_state[object_id])
					print("[SaveSystem] Đã khôi phục: " + object_id)
			else:
				print("[SaveSystem] Không tìm thấy đối tượng: " + object_id)
	
	# Khôi phục trạng thái cửa
	if data.has("door_states"):
		print("[SaveSystem] Đang khôi phục trạng thái cửa...")
		door_states = data["door_states"].duplicate()
		
		# Cập nhật các cửa hiện có trong scene
		var all_doors = []
		all_doors.append_array(get_tree().get_nodes_in_group("StorageDoors"))
		all_doors.append_array(get_tree().get_nodes_in_group("SecurityDoors"))
		
		for door in all_doors:
			if door.has_method("get_door_id") and door_states.has(door.get_door_id()):
				door.load_state(door_states[door.get_door_id()])
				print("[SaveSystem] Đã khôi phục trạng thái cửa: " + door.get_door_id())
	
	# Reset các tham chiếu tạm thời
	reset_temporary_references()

# Reset các tham chiếu tạm thời sau khi tải game
func reset_temporary_references():
	# Reset tham chiếu nearby_workbench của người chơi
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("reset_interaction_references"):
		player.reset_interaction_references()

# Kiểm tra xem có file lưu game hay không cho slot cụ thể
func has_save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false
	return FileAccess.file_exists(get_save_file_path(slot))

# Lấy thông tin về file lưu game cho slot cụ thể
func get_save_info(slot: int) -> Dictionary:
	if has_save_game(slot):
		var file_path = get_save_file_path(slot)
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json_result = JSON.parse_string(json_string)
			if json_result:
				return {
					"exists": true,
					"name": json_result.get("save_name", "Bản lưu #" + str(slot + 1)),
					"time": json_result.get("save_time", "")
				}
	
	return {
		"exists": false,
		"name": "",
		"time": ""
	}

# Lấy thông tin về tất cả các slot lưu game
func get_all_save_info() -> Array:
	var result = []
	for i in range(MAX_SAVE_SLOTS):
		result.append(get_save_info(i))
	return result

# Reset tất cả các biến về trạng thái ban đầu
func reset_to_initial_state():
	# Reset dữ liệu game hiện tại
	current_game_state = {}
	
	# Giữ nguyên danh sách các đối tượng đã đăng ký
	# nhưng xóa các dữ liệu cache
	scene_transition_cache = {}
	door_states = {}
	
	print("[SaveSystem] Đã reset tất cả các biến về trạng thái ban đầu")

# Xóa file lưu game cho slot cụ thể
func delete_save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		print("[SaveSystem] Slot không hợp lệ: " + str(slot))
		return false
		
	var file_path = get_save_file_path(slot)
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://")
		if dir:
			var error = dir.remove(file_path)
			if error == OK:
				print("[SaveSystem] Đã xóa file lưu game ở slot " + str(slot))
				return true
			else:
				print("[SaveSystem] Không thể xóa file lưu game ở slot " + str(slot))
	else:
		print("[SaveSystem] Không có file lưu game ở slot " + str(slot))
	return false

# Lấy vị trí người chơi
func get_player_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player.global_position
	return Vector2.ZERO

# Thiết lập vị trí người chơi
func set_player_position(position: Vector2):
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.global_position = position

# Cập nhật UI inventory sau khi tải game
func update_inventory_ui():
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui:
		# Gọi hàm cập nhật tổng thể từ UserInterface
		ui.update_all_ui()
		print("[SaveSystem] Đã yêu cầu UserInterface cập nhật UI")

# Lưu trạng thái tạm thời trước khi chuyển cảnh
func persist_state_for_transition() -> void:
	print("[SaveSystem] Lưu trạng thái tạm thời trước khi chuyển cảnh...")
	
	# Lưu trạng thái của các đối tượng đã đăng ký vào cache
	for object_id in saveable_objects:
		var object = saveable_objects[object_id]
		if is_instance_valid(object) and object.has_method("save_state"):
			scene_transition_cache[object_id] = object.save_state()
			print("[SaveSystem] Đã lưu trạng thái vào cache: " + object_id)
	
	print("[SaveSystem] Đã lưu " + str(scene_transition_cache.size()) + " đối tượng vào cache")

# Xóa cache sau khi đã khôi phục tất cả trạng thái
func clear_transition_cache() -> void:
	scene_transition_cache.clear()
	print("[SaveSystem] Đã xóa cache chuyển cảnh")

# Lưu trạng thái của cửa
func save_door_state(door_id: String, state: Dictionary) -> void:
	door_states[door_id] = state
	print("[SaveSystem] Đã lưu trạng thái cửa: " + door_id)
	
	# Lưu vào cache chuyển cảnh để duy trì qua các lần chuyển cảnh
	scene_transition_cache[door_id] = state
	
	# Thêm vào current_game_state để lưu vào file save nếu người chơi lưu game
	if not current_game_state.has("door_states"):
		current_game_state["door_states"] = {}
	current_game_state["door_states"][door_id] = state

# Lấy trạng thái của cửa
func get_door_state(door_id: String) -> Dictionary:
	# Kiểm tra trong bộ nhớ đệm trước
	if door_states.has(door_id):
		print("[SaveSystem] Đã tìm thấy trạng thái cửa trong bộ nhớ đệm: " + door_id)
		return door_states[door_id]
	
	# Kiểm tra trong cache chuyển cảnh
	if scene_transition_cache.has(door_id):
		print("[SaveSystem] Đã tìm thấy trạng thái cửa trong cache chuyển cảnh: " + door_id)
		door_states[door_id] = scene_transition_cache[door_id]
		return scene_transition_cache[door_id]
	
	# Kiểm tra trong current_game_state nếu có
	if current_game_state.has("door_states") and current_game_state["door_states"].has(door_id):
		print("[SaveSystem] Đã tìm thấy trạng thái cửa trong current_game_state: " + door_id)
		var state = current_game_state["door_states"][door_id]
		door_states[door_id] = state
		return state
	
	print("[SaveSystem] Không tìm thấy trạng thái cửa: " + door_id)
	return {}
