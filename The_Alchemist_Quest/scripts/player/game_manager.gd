extends Node

# Dữ liệu về vị trí xuất hiện của người chơi khi chuyển scene
var player_spawn_data = null

# Vị trí người chơi khi vào phòng security
var security_door_entry_position: Vector2 = Vector2.ZERO

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
		
		# Cập nhật trạng thái cửa security nếu người chơi đang quay về từ phòng security
		var from_security = player_spawn_data.from_security_room
		if from_security:
			print("[GameManager] Người chơi đang quay về từ phòng security, cập nhật trạng thái cửa")
			# Tìm cửa security trong scene và đánh dấu đã vào
			_update_security_door_state()
		
		# Reset dữ liệu sau khi đã sử dụng
		player_spawn_data = null
		
		return from_security
	return false
	
# Hàm mới để cập nhật trạng thái cửa security
func _update_security_door_state():
	# Tìm tất cả các node có script security_door.gd
	var security_doors = get_tree().get_nodes_in_group("SecurityDoors")
	print("[GameManager DEBUG] Tìm thấy", security_doors.size(), "cửa trong nhóm SecurityDoors")
	
	if security_doors.size() == 0:
		# Nếu không tìm thấy cửa trong nhóm, thử tìm theo đường dẫn hoặc tên
		var potential_door = get_tree().get_first_node_in_group("Workbench")
		if potential_door and potential_door.get_script().resource_path.ends_with("security_door.gd"):
			security_doors = [potential_door]
	
	if security_doors.size() > 0:
		for door in security_doors:
			if door.has_method("get_saveable_id"):
				var door_id = door.get_saveable_id()
				print("[GameManager] Kiểm tra cửa với ID:", door_id)
				if door_id.begins_with("door_security") or door_id.begins_with("door_main_security"):
					print("[GameManager] Đánh dấu cửa security đã được vào:", door_id)
					door.has_been_entered = true
					door.is_door_open = true
					return
	
	print("[GameManager] Không tìm thấy cửa security trong scene")

# Lưu vị trí hiện tại của người chơi để sử dụng sau khi chuyển scene
func save_player_position(position: Vector2, source_name: String = ""):
	player_spawn_data = {
		"position": position,
		"source_name": source_name,
		"from_security_room": false
	}
	print("[GameManager] Đã lưu vị trí người chơi:", position, "từ nguồn:", source_name) 