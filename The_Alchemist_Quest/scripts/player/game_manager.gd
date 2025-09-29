extends Node

# Dữ liệu về vị trí xuất hiện của người chơi khi chuyển scene
var player_spawn_data = null

# Vị trí người chơi khi vào phòng security
var security_door_entry_position: Vector2 = Vector2.ZERO
# Vị trí người chơi khi vào phòng storage
var storage_door_entry_position: Vector2 = Vector2.ZERO

# Biến lưu trữ trạng thái của các cánh cửa
var door_states = {}

# Trạng thái thanh máu
var health_state = {
	"remaining_time": 90.0,
	"is_visible": true
}

# Trạng thái hệ thống thông gió
var ventilation_system_state = {
	"is_ventilation_fixed": false
}

# Thêm trạng thái hệ thống điện
var power_state = {
	"is_power_on": false
}

func _ready():
	print("[GameManager] Khởi tạo thành công")
	
	# Kết nối signal để đăng ký các cửa sau khi scene được tải
	get_tree().node_added.connect(_check_node_for_registration)

# Kiểm tra và đăng ký các node được thêm vào scene tree
func _check_node_for_registration(node: Node):
	# Kiểm tra nếu node là cửa
	if node.get_script() and (str(node.get_script().resource_path).contains("storage_door.gd") or 
							  str(node.get_script().resource_path).contains("security_door.gd")):
		print("[GameManager] Phát hiện cửa mới: ", node.name)
		
		# Đảm bảo SaveLoadManager đã được khởi tạo
		if get_node_or_null("/root/SaveLoadManager") and node.has_method("get_saveable_id"):
			var door_id = node.get_saveable_id()
			print("[GameManager] Đăng ký cửa với ID: ", door_id)
			get_node("/root/SaveLoadManager").register_saveable_object(node)
	
	# Kiểm tra nếu node là hệ thống thông gió
	elif node.get_script() and str(node.get_script().resource_path).contains("ventilation_control_system.gd"):
		print("[GameManager] Phát hiện hệ thống thông gió mới: ", node.name)
		
		# Đảm bảo SaveLoadManager đã được khởi tạo
		if get_node_or_null("/root/SaveLoadManager") and node.has_method("get_saveable_id"):
			var system_id = node.get_saveable_id()
			print("[GameManager] Đăng ký hệ thống thông gió với ID: ", system_id)
			get_node("/root/SaveLoadManager").register_saveable_object(node)
			
			# Áp dụng trạng thái từ GameManager
			if ventilation_system_state.has("is_ventilation_fixed") and ventilation_system_state["is_ventilation_fixed"]:
				node.is_ventilation_fixed = true
				if node.has_method("_apply_ventilation_fixed_state"):
					node.call("_apply_ventilation_fixed_state")
					print("[GameManager] Áp dụng trạng thái đã sửa cho hệ thống thông gió")
	
	# Kiểm tra nếu node là quạt thông gió
	elif node.get_script() and str(node.get_script().resource_path).contains("ventilation_fan_decor.gd"):
		print("[GameManager] Phát hiện quạt thông gió mới: ", node.name)
		
		# Đảm bảo SaveLoadManager đã được khởi tạo
		if get_node_or_null("/root/SaveLoadManager") and node.has_method("get_saveable_id"):
			var fan_id = node.get_saveable_id()
			print("[GameManager] Đăng ký quạt thông gió với ID: ", fan_id)
			get_node("/root/SaveLoadManager").register_saveable_object(node)
			
			# Áp dụng trạng thái từ GameManager
			if ventilation_system_state.has("is_ventilation_fixed") and ventilation_system_state["is_ventilation_fixed"]:
				if node.has_method("activate"):
					node.call("activate")
					print("[GameManager] Kích hoạt quạt thông gió")

# Đặt vị trí người chơi sau khi chuyển scene
func place_player_at_position():
	if player_spawn_data == null:
		print("[GameManager] Không có dữ liệu spawn, sử dụng vị trí mặc định")
		return false
	
	print("[GameManager] Đặt người chơi tại vị trí từ scene trước:", player_spawn_data.position)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.global_position = player_spawn_data.position
		print("[GameManager] Đã đặt người chơi tại vị trí:", player_spawn_data.position)
		
		# Cập nhật trạng thái cửa security hoặc storage nếu người chơi đang quay về từ phòng đó
		var from_security = player_spawn_data.from_security_room
		var from_storage = player_spawn_data.from_storage_room
		
		if from_security:
			print("[GameManager] Người chơi đang quay về từ phòng security, cập nhật trạng thái cửa")
			# Tìm cửa security trong scene và đánh dấu đã vào
			_update_door_state("SecurityDoors", "door_security", "door_main_security")
		
		if from_storage:
			print("[GameManager] Người chơi đang quay về từ phòng storage, cập nhật trạng thái cửa")
			# Tìm cửa storage trong scene và đánh dấu đã vào
			_update_door_state("StorageDoors", "door_storage", "door_storage_main")
		
		# Reset dữ liệu sau khi đã sử dụng
		player_spawn_data = null
		
		return from_security or from_storage
	return false
	
# Hàm cập nhật trạng thái cửa (chung cho cả security và storage)
func _update_door_state(door_group: String, door_id_prefix1: String, door_id_prefix2: String):
	# Tìm tất cả các node có trong nhóm cửa cần cập nhật
	var doors = get_tree().get_nodes_in_group(door_group)
	print("[GameManager DEBUG] Tìm thấy", doors.size(), "cửa trong nhóm", door_group)
	
	if doors.size() == 0:
		# Nếu không tìm thấy cửa trong nhóm, thử tìm theo đường dẫn hoặc tên
		var potential_door = get_tree().get_first_node_in_group("Workbench")
		if potential_door and potential_door.get_script().resource_path.ends_with(door_group.to_lower().substr(0, door_group.length() - 1) + ".gd"):
			doors = [potential_door]
	
	if doors.size() > 0:
		for door in doors:
			if door.has_method("get_saveable_id"):
				var door_id = door.get_saveable_id()
				print("[GameManager] Kiểm tra cửa với ID:", door_id)
				if door_id.begins_with(door_id_prefix1) or door_id.begins_with(door_id_prefix2):
					print("[GameManager] Đánh dấu cửa", door_group, "đã được vào:", door_id)
					door.has_been_entered = true
					door.is_door_open = true
					return
	
	print("[GameManager] Không tìm thấy cửa", door_group, "trong scene")

# Lưu vị trí hiện tại của người chơi để sử dụng sau khi chuyển scene
func save_player_position(position: Vector2, source_name: String = ""):
	player_spawn_data = {
		"position": position,
		"source_name": source_name,
		"from_security_room": source_name.contains("security"),
		"from_storage_room": source_name.contains("storage")
	}
	print("[GameManager] Đã lưu vị trí người chơi:", position, "từ nguồn:", source_name)
	print("[GameManager] Cờ from_security_room:", player_spawn_data.from_security_room)
	print("[GameManager] Cờ from_storage_room:", player_spawn_data.from_storage_room) 

# Reset tất cả các biến về trạng thái ban đầu
func reset_to_initial_state():
	# Reset vị trí spawn
	player_spawn_data = null
	
	# Reset vị trí cửa
	security_door_entry_position = Vector2.ZERO
	storage_door_entry_position = Vector2.ZERO
	
	# Reset trạng thái cửa
	door_states = {}
	
	# Reset trạng thái thanh máu
	health_state = {
		"remaining_time": 90.0,
		"is_visible": true
	}
	
	# Reset trạng thái hệ thống thông gió
	ventilation_system_state = {
		"is_ventilation_fixed": false
	}
	
	print("[GameManager] Đã reset tất cả các biến về trạng thái ban đầu")
