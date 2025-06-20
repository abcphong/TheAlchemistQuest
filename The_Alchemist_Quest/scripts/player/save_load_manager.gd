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

func _ready():
	print("SaveLoadManager is ready")

# Đăng ký đối tượng có thể lưu trạng thái
func register_saveable_object(object: Node) -> void:
	if object.has_method("get_saveable_id") and object.has_method("save_state") and object.has_method("load_state"):
		var object_id = object.get_saveable_id()
		saveable_objects[object_id] = object
		print("[SaveSystem] Đăng ký đối tượng: " + object_id)
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
	
	# Tạo dictionary chứa tất cả dữ liệu cần lưu
	var save_data = {
		# Thông tin bản lưu
		"save_name": save_name,
		"save_time": Time.get_datetime_string_from_system(),
		# Player data
		"player_position_x": get_player_position().x,
		"player_position_y": get_player_position().y,
		"player_health": get_player_health(),
		# Inventory data
		"inventory": inventory_data,
		"hotbar": hotbar_data,
		# Checkpoint data
		"checkpoint_position_x": CheckpointManager.current_checkpoint_position.x,
		"checkpoint_position_y": CheckpointManager.current_checkpoint_position.y,
		# Trạng thái các đối tượng trong game
		"objects_state": objects_state,
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
	set_player_health(data["player_health"])
	
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

# Lấy sức khỏe người chơi
func get_player_health() -> String:
	var health_bar = get_tree().get_first_node_in_group("HealthBar")
	if health_bar:
		return health_bar.current_animation
	return "Green"

# Thiết lập sức khỏe người chơi
func set_player_health(health_state: String):
	var health_bar = get_tree().get_first_node_in_group("HealthBar")
	if health_bar:
		health_bar.current_animation = health_state
		health_bar.play_animation_once(health_state)

# Cập nhật UI inventory sau khi tải game
func update_inventory_ui():
	# Cập nhật inventory
	var inventory_ui = get_tree().root.find_child("Inventory", true, false)
	if inventory_ui and inventory_ui.has_method("initialize_inventory"):
		inventory_ui.initialize_inventory()
	
	# Cập nhật hotbar
	var hotbar_ui = get_tree().root.find_child("Hotbar", true, false)
	if hotbar_ui and hotbar_ui.has_method("initialize_hotbar"):
		hotbar_ui.initialize_hotbar()
