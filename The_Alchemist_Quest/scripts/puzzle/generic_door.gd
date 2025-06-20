extends Node2D

# ID duy nhất của cửa
@export var door_id: String = "generic_door"
@export var open_door_texture: Texture2D
@export var closed_door_texture: Texture2D

# Biến theo dõi trạng thái
var is_door_open: bool = false

# Hàm khởi tạo
func _ready():
	# Đăng ký với SaveLoadManager
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)
	
	# Kiểm tra xem có node DoorSprite không
	if not has_node("DoorSprite"):
		print("[GenericDoor] Lỗi: Không tìm thấy node DoorSprite")

# Mở cửa
func open_door():
	is_door_open = true
	update_door_state(true)
	print("[GenericDoor] Đã mở cửa: ", door_id)

# Đóng cửa
func close_door():
	is_door_open = false
	update_door_state(false)
	print("[GenericDoor] Đã đóng cửa: ", door_id)

# Cập nhật trạng thái cửa
func update_door_state(is_open: bool):
	if has_node("DoorSprite"):
		var sprite = get_node("DoorSprite")
		if is_open and open_door_texture:
			sprite.texture = open_door_texture
		elif not is_open and closed_door_texture:
			sprite.texture = closed_door_texture
		
		print("[GenericDoor] Cập nhật trạng thái cửa ", door_id, ": ", "mở" if is_open else "đóng")

# Chuyển đổi trạng thái (mở/đóng)
func toggle_door():
	if is_door_open:
		close_door()
	else:
		open_door()

# Lấy ID của cửa
func get_saveable_id() -> String:
	return "door_" + door_id

# Lưu trạng thái
func save_state() -> Dictionary:
	var state = {
		"door_id": door_id,
		"is_door_open": is_door_open
	}
	print("[SaveSystem] Cửa '", door_id, "' lưu trạng thái: open=", is_door_open)
	return state

# Tải trạng thái
func load_state(state: Dictionary) -> void:
	if state.has("door_id") and state["door_id"] == door_id:
		if state.has("is_door_open"):
			is_door_open = state["is_door_open"]
			update_door_state(is_door_open)
			print("[SaveSystem] Cửa '", door_id, "' tải trạng thái: open=", is_door_open) 