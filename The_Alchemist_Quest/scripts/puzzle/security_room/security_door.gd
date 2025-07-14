extends "res://The_Alchemist_Quest/scripts/puzzle/storage_door.gd"

@export var security_room_scene: String = "res://The_Alchemist_Quest/scences/security_room_level.tscn"
@export var unlocked_door_texture: Texture2D

# Biến player và is_puzzle_completed được khai báo trong lớp cha
var has_been_entered: bool = false  # Biến mới để theo dõi trạng thái đã vào phòng security

func _ready():
	super._ready()
	# ID đã được thiết lập trong scene
	
	# Thêm cửa vào nhóm SecurityDoors để dễ tìm trong GameManager
	add_to_group("SecurityDoors")
	
	print("[Security Door] Khởi tạo door_id:", door_id)
	print("[Security Door] Đường dẫn security_room_scene:", security_room_scene)
	
	# Đảm bảo security_room_scene đã được thiết lập
	if security_room_scene.is_empty():
		security_room_scene = "res://The_Alchemist_Quest/scences/security_room_level.tscn"
		print("[Security Door] Đã thiết lập lại đường dẫn scene mặc định")
	
# Đã được xử lý bởi lớp cha

# Ghi đè phương thức update_door_state của lớp cha
func update_door_state(is_open: bool):
	# Chỉ xử lý logic, không cần thay đổi texture
	# Texture sẽ được xử lý trong _on_puzzle_completed
	if is_open:
		print("[Security Door] Cập nhật trạng thái cửa security: đã mở")
	else:
		print("[Security Door] Cập nhật trạng thái cửa security: đã đóng")
		
# Ghi đè phương thức _on_puzzle_completed của lớp cha
func _on_puzzle_completed():
	super._on_puzzle_completed()
	
	# Cập nhật texture của cửa nếu có
	if unlocked_door_texture != null and has_node("DoorSprite"):
		$DoorSprite.texture = unlocked_door_texture
	
	print("[Security Door] Puzzle completed: " + str(puzzle_completed_flags))
	
	# Lưu trạng thái cửa sau khi hoàn thành puzzle
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		save_load_manager.save_door_state(door_id, save_state())
		print("[Security Door] Đã lưu trạng thái cửa sau khi hoàn thành puzzle")

# Ghi đè phương thức save_state của lớp cha
func save_state() -> Dictionary:
	var state = super.save_state()
	state["has_been_entered"] = has_been_entered
	print("[SaveSystem] Security Door '" + door_id + "' lưu trạng thái đã vào: " + str(has_been_entered))
	return state

# Ghi đè phương thức load_state của lớp cha
func load_state(state: Dictionary) -> void:
	super.load_state(state)
	if state.has("has_been_entered"):
		has_been_entered = state["has_been_entered"]
		print("[SaveSystem] Security Door '" + door_id + "' tải trạng thái đã vào: " + str(has_been_entered))
		
# Ghi đè phương thức open_puzzle_ui
func open_puzzle_ui():
	print("[Security Door DEBUG] open_puzzle_ui được gọi, door_id:", door_id)
	print("[Security Door DEBUG] Trạng thái puzzle_completed_flags:", puzzle_completed_flags)
	print("[Security Door DEBUG] has_been_entered:", has_been_entered)
	print("[Security Door DEBUG] all_puzzles_completed():", all_puzzles_completed())
	
	if all_puzzles_completed():
		# Nếu đã giải xong tất cả câu đố, chuyển đến phòng bảo mật
		# Đánh dấu đã vào phòng security
		has_been_entered = true
		is_door_open = true  # Đánh dấu cửa đã mở
		print("[Security Door] Đánh dấu cửa đã được vào: " + door_id)
		print("[Security Door] Chuyển đến scene: " + security_room_scene)
		
		# Lưu vị trí của người chơi khi vào phòng security
		var player = get_tree().get_first_node_in_group("Player")
		if player and get_node_or_null("/root/GameManager"):
			var player_position = player.global_position
			print("[Security Door] Lưu vị trí người chơi trước khi vào phòng:", player_position)
			# Lưu vị trí vào cả hai biến để đảm bảo tương thích với cả hai cách
			var game_manager = get_node("/root/GameManager")
			game_manager.security_door_entry_position = player_position
			# Thêm dòng này để sử dụng hàm save_player_position
			game_manager.save_player_position(player_position, "security_door_entry")
		
		# Lưu trạng thái tạm thời trước khi chuyển cảnh
		var save_load_manager = get_node_or_null("/root/SaveLoadManager")
		if save_load_manager:
			# Lưu trạng thái cửa trước
			save_load_manager.save_door_state(door_id, save_state())
			# Sau đó lưu trạng thái tạm thời
			save_load_manager.persist_state_for_transition()
			print("[Security Door] Đã lưu trạng thái tạm thời trước khi chuyển cảnh")
			
		get_tree().change_scene_to_file(security_room_scene)
	else:
		# Nếu chưa giải xong câu đố, mở UI câu đố
		print("[Security Door DEBUG] Mở UI puzzle vì chưa hoàn thành tất cả câu đố")
		super.open_puzzle_ui()
		
# Ghi đè phương thức all_puzzles_completed của lớp cha
func all_puzzles_completed() -> bool:
	# Nếu đã từng vào phòng security, luôn cho phép vào mà không cần kiểm tra puzzle
	if has_been_entered:
		return true
		
	# Kiểm tra các puzzle nếu chưa từng vào phòng
	for completed in puzzle_completed_flags:
		if not completed:
			return false
	return puzzle_completed_flags.size() > 0 
