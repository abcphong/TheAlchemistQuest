extends "res://The_Alchemist_Quest/scripts/puzzle/storage_door.gd"

# Đường dẫn đến scene phòng bảo mật
@export var security_room_scene: String = "res://The_Alchemist_Quest/scences/security_room_level.tscn"

# Ghi đè hàm open_puzzle_ui để xử lý trường hợp đặc biệt khi tất cả puzzle đã hoàn thành
func open_puzzle_ui():
	# Nếu đã hoàn tất mọi puzzle, chuyển đến phòng bảo mật
	if current_puzzle_index >= puzzle_scenes.size():
		print("[SecurityDoor] Tất cả puzzle đã hoàn thành, chuyển đến phòng bảo mật")
		_enter_security_room()
		return
		
	# Nếu chưa hoàn thành, gọi hàm gốc
	super.open_puzzle_ui()

# Hàm để vào phòng bảo mật
func _enter_security_room():
	# Chuyển đến scene phòng bảo mật
	print("[SecurityDoor] Chuyển đến scene phòng bảo mật: " + security_room_scene)
	get_tree().change_scene_to_file(security_room_scene) 
