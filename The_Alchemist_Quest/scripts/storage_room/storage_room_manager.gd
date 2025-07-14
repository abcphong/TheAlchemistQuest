extends Node

# Vị trí người chơi khi quay trở lại phòng chính
@export var exit_position: Vector2 = Vector2(0, 0)
@export var main_scene: String = "res://The_Alchemist_Quest/scences/game.tscn"

# Tham chiếu đến các node
@onready var player = get_node_or_null("Player")
@onready var interaction_prompt = get_node_or_null("InteractionPrompt")
@onready var exit_door = get_node_or_null("ExitDoor")

# Biến theo dõi trạng thái
var player_in_exit_area = false
var exit_door_active = false
var items_added = false

func _ready():
	print("[StorageRoomManager] Khởi tạo phòng lưu trữ")
	
	# Đặt người chơi vào vị trí đúng khi vào phòng
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.storage_door_entry_position != Vector2.ZERO:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.global_position = game_manager.storage_door_entry_position
			print("[StorageRoomManager] Đặt người chơi tại vị trí:", game_manager.storage_door_entry_position)
	
	# Kết nối tín hiệu từ cửa ra
	if exit_door:
		exit_door.body_entered.connect(_on_exit_door_body_entered)
		exit_door.body_exited.connect(_on_exit_door_body_exited)
		
	# Ẩn thông báo tương tác ban đầu
	if interaction_prompt:
		interaction_prompt.visible = false
		
	# Thêm các item vào inventory khi người chơi vào phòng
	# add_items_to_inventory()

func _process(delta):
	# Xử lý tương tác với cửa ra
	if exit_door_active and Input.is_action_just_pressed("interact"):
		exit_room()

# Thêm các item vào inventory khi người chơi vào phòng
#func add_items_to_inventory():
#	if items_added:
#		return
#		
#	var ui = get_tree().get_first_node_in_group("UserInterface")
#	if ui:
#		# Task 1 items
#		ui.add_new_item_to_inventory("HCl", 1)
#		ui.add_new_item_to_inventory("H2O2", 1)
#		ui.add_new_item_to_inventory("Corrosion_reaction_note", 1)
#		
#		# Task 2 items
#		ui.add_new_item_to_inventory("Na2S2O3", 1)
#		ui.add_new_item_to_inventory("H2O", 1)
#		ui.add_new_item_to_inventory("Note_Na2S2O3+H2O", 1)
#		
#		items_added = true
#		print("[StorageRoomManager] Đã thêm các item vào inventory")
#	else:
#		print("[StorageRoomManager] Không tìm thấy UserInterface để thêm item")

# Xử lý khi người chơi vào vùng cửa ra
func _on_exit_door_body_entered(body):
	if body.is_in_group("Player"):
		player_in_exit_area = true
		exit_door_active = true
		if interaction_prompt:
			interaction_prompt.visible = true
			print("[StorageRoomManager] Người chơi đã vào vùng cửa ra")

# Xử lý khi người chơi rời vùng cửa ra
func _on_exit_door_body_exited(body):
	if body.is_in_group("Player"):
		player_in_exit_area = false
		exit_door_active = false
		if interaction_prompt:
			interaction_prompt.visible = false
			print("[StorageRoomManager] Người chơi đã rời vùng cửa ra")

# Xử lý khi người chơi tương tác với cửa ra
func exit_room():
	print("[StorageRoomManager] Người chơi rời khỏi phòng lưu trữ")
	
	# Lấy vị trí entry từ GameManager nếu có, nếu không thì dùng vị trí mặc định
	var return_position = exit_position
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.storage_door_entry_position != Vector2.ZERO:
		return_position = game_manager.storage_door_entry_position
		print("[StorageRoomManager] Sử dụng vị trí đã lưu để quay về:", return_position)
	else:
		print("[StorageRoomManager] Không tìm thấy vị trí vào, sử dụng vị trí mặc định:", return_position)
	
	# Sử dụng hàm save_player_position thay vì gán trực tiếp vào player_spawn_data
	if game_manager:
		game_manager.save_player_position(return_position, "storage_room")
		game_manager.player_spawn_data["from_storage_room"] = true
		print("[StorageRoomManager] Đã lưu vị trí quay về:", return_position)
	
	# Lưu trạng thái tạm thời trước khi chuyển cảnh
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		save_load_manager.persist_state_for_transition()
		print("[StorageRoomManager] Đã lưu trạng thái tạm thời trước khi chuyển cảnh")
	
	# Chuyển về phòng chính
	get_tree().change_scene_to_file(main_scene) 
