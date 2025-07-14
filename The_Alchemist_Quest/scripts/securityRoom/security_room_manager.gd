extends Node2D

# Tham chiếu đến các node tương tác
@onready var ventilation_fan = get_node_or_null("Decor/VentilationFan")
@onready var red_beacon = get_node_or_null("Decor/RedBeacon")
@onready var exit_area = $Door/ExitArea
@onready var monitor_interaction = $InteractionPoints/MonitorInteraction
@onready var cabinet_interaction = get_node_or_null("InteractionPoints/CabinetInteraction")
@onready var interaction_prompt = $InteractionPrompt
@onready var player = $Player
@onready var spawn_point = $SpawnPoint
@onready var door_sprite = $Door/DoorSprite
@onready var health_bar = get_node_or_null("UI/HealthBar") # Tham chiếu đến HealthBar

# Đường dẫn đến scene giao diện màn hình giám sát
const SECURITY_MONITOR_UI_PATH = "res://The_Alchemist_Quest/scences/puzzle/security_room/security_monitor_ui.tscn"

# Biến theo dõi trạng thái
var player_in_monitor_area = false
var player_in_cabinet_area = false
var player_in_exit_area = false
var room_entry_cooldown = false  # Cờ để tránh thoát phòng ngay lập tức khi mới vào - đã tắt để cho phép thoát ngay lập tức
var exit_door_active = false    # Cờ để theo dõi trạng thái cửa thoát
var monitor_ui_active = false   # Cờ để theo dõi trạng thái giao diện màn hình giám sát

# Vị trí cửa trong scene gốc
const SECURITY_DOOR_POSITION = Vector2(2043, 744)  # Vị trí của SecurityDoor trong room 1.tscn
const GAME_SCENE_PATH = "res://The_Alchemist_Quest/scences/game.tscn"  # Đường dẫn đến scene gốc

# Tham chiếu đến player
var current_interactable = null

func _ready():
	# Kết nối tín hiệu từ các vùng tương tác với kiểm tra null
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
		exit_area.body_exited.connect(_on_exit_area_body_exited)
	else:
		print("[SecurityRoom] Lỗi: Không tìm thấy exit_area")
	
	if monitor_interaction:
		monitor_interaction.body_entered.connect(_on_monitor_interaction_body_entered)
		monitor_interaction.body_exited.connect(_on_interaction_body_exited)
	else:
		print("[SecurityRoom] Lỗi: Không tìm thấy monitor_interaction")
	
	if cabinet_interaction:
		cabinet_interaction.body_entered.connect(_on_cabinet_interaction_body_entered)
		cabinet_interaction.body_exited.connect(_on_interaction_body_exited)
	else:
		print("[SecurityRoom] Lỗi: Không tìm thấy cabinet_interaction")
	
	# Khởi tạo animation
	if ventilation_fan:
		ventilation_fan.play("default")
	
	if red_beacon:
		red_beacon.play("default")
	
	# Ẩn thông báo tương tác ban đầu
	if interaction_prompt:
		interaction_prompt.visible = false
	
	# Cài đặt tốc độ animation
	if ventilation_fan:
		ventilation_fan.speed_scale = 1.0
	
	if red_beacon:
		red_beacon.speed_scale = 0.5

	# Đặt vị trí player tại điểm spawn
	if player and spawn_point:
		player.global_position = spawn_point.global_position
		print("[SecurityRoom] Đã đặt player tại điểm spawn")
		
		# Kết nối HealthBar với player sprite nếu có
		if health_bar and player.has_node("AnimatedSprite2D"):
			health_bar.player_sprite = player.get_node("AnimatedSprite2D")
			print("[SecurityRoom] Đã kết nối HealthBar với player sprite")
			
			# Tải trạng thái thanh máu từ GameManager nếu có
			health_bar.load_health_state()
			print("[SecurityRoom] Đã tải trạng thái thanh máu")
	
	# Đăng ký với SaveLoadManager để lưu/tải trạng thái
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)

	print("[SecurityRoom] Phòng bảo mật đã khởi tạo")
	
	# Đã bỏ thiết lập hẹn giờ để cho phép thoát ngay lập tức
	print("[SecurityRoom] Không có cooldown, người chơi có thể thoát phòng ngay lập tức")

# Lưu trạng thái của security room
func save_state() -> Dictionary:
	var state = {
		"exit_door_active": exit_door_active
	}
	print("[SaveSystem] Security Room lưu trạng thái: exit_door_active=" + str(exit_door_active))
	return state

# Tải trạng thái của security room
func load_state(state: Dictionary) -> void:
	if state.has("exit_door_active"):
		exit_door_active = state["exit_door_active"]
		print("[SaveSystem] Security Room tải trạng thái: exit_door_active=" + str(exit_door_active))

# Lấy ID của security room
func get_saveable_id() -> String:
	return "security_room_manager"

func _process(delta):
	if current_interactable != null and player != null:
		if Input.is_action_just_pressed("interact"):
			match current_interactable:
				"monitor":
					_handle_monitor_interaction()
				"cabinet":
					_handle_cabinet_interaction()
				"exit_door":
					_exit_room()
					
	# Chỉ sử dụng E để thoát nếu đang đứng gần cửa
	if exit_door_active and Input.is_action_just_pressed("interact"):
		_exit_room()

# Xử lý tương tác với màn hình giám sát
func _handle_monitor_interaction():
	print("[SecurityRoom] Tương tác với màn hình giám sát")
	
	# Kiểm tra xem giao diện màn hình giám sát đã được hiển thị chưa
	if monitor_ui_active:
		print("[SecurityRoom] Giao diện màn hình giám sát đã được hiển thị")
		return
	
	# Hiển thị giao diện màn hình giám sát
	var monitor_ui_scene = load(SECURITY_MONITOR_UI_PATH)
	if monitor_ui_scene:
		var monitor_ui = monitor_ui_scene.instantiate()
		add_child(monitor_ui)
		monitor_ui_active = true
		
		# Kết nối tín hiệu để biết khi nào giao diện bị đóng
		monitor_ui.tree_exited.connect(_on_monitor_ui_closed)
		
		print("[SecurityRoom] Đã hiển thị giao diện màn hình giám sát")
	else:
		print("[SecurityRoom] Lỗi: Không thể tải scene giao diện màn hình giám sát")

# Xử lý khi giao diện màn hình giám sát bị đóng
func _on_monitor_ui_closed():
	monitor_ui_active = false
	print("[SecurityRoom] Giao diện màn hình giám sát đã bị đóng")

# Xử lý tương tác với tủ hóa chất
func _handle_cabinet_interaction():
	if cabinet_interaction == null:
		return
		
	print("[SecurityRoom] Tương tác với tủ hóa chất")
	# Mở inventory hoặc thêm item vào inventory
	# TODO: Thêm code mở inventory hoặc thêm item

# Xử lý thoát khỏi phòng
func _exit_room():
	print("[SecurityRoom] Thoát khỏi phòng bảo mật")
	
	# Lấy vị trí entry từ GameManager nếu có, nếu không thì dùng vị trí mặc định
	var return_position = SECURITY_DOOR_POSITION
	var game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager and game_manager.security_door_entry_position != Vector2.ZERO:
		return_position = game_manager.security_door_entry_position
		print("[SecurityRoom] Sử dụng vị trí đã lưu để quay về:", return_position)
	else:
		print("[SecurityRoom] Không tìm thấy vị trí vào, sử dụng vị trí mặc định:", return_position)
	
	# Sử dụng hàm save_player_position thay vì gán trực tiếp vào player_spawn_data
	if game_manager:
		game_manager.save_player_position(return_position, "security_room")
		game_manager.player_spawn_data["from_security_room"] = true
		print("[SecurityRoom] Đã lưu vị trí người chơi để quay về:", return_position)
	
	# Lưu trạng thái tạm thời trước khi chuyển cảnh
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		save_load_manager.persist_state_for_transition()
		print("[SecurityRoom] Đã lưu trạng thái tạm thời trước khi chuyển cảnh")
	
	# Chuyển về scene chính
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

# Xử lý khi người chơi vào vùng tương tác màn hình
func _on_monitor_interaction_body_entered(body):
	if body.name == "Player":
		player = body
		current_interactable = "monitor"
		if interaction_prompt:
			interaction_prompt.text = "Nhấn E để kiểm tra màn hình"
			interaction_prompt.visible = true

# Xử lý khi người chơi rời vùng tương tác màn hình
func _on_interaction_body_exited(body):
	if body.name == "Player":
		player = body
		current_interactable = null
		if interaction_prompt:
			interaction_prompt.visible = false

# Xử lý khi người chơi vào vùng tương tác tủ
func _on_cabinet_interaction_body_entered(body):
	if cabinet_interaction == null:
		return
		
	if body.name == "Player":
		player = body
		current_interactable = "cabinet"
		if interaction_prompt:
			interaction_prompt.text = "Nhấn E để mở tủ hóa chất"
			interaction_prompt.visible = true

# Xử lý khi người chơi vào vùng thoát
func _on_exit_area_body_entered(body):
	if body.name == "Player": # Đã bỏ điều kiện room_entry_cooldown để cho phép thoát ngay lập tức
		player = body
		exit_door_active = true
		current_interactable = "exit_door"
		if interaction_prompt:
			interaction_prompt.text = "Nhấn E để quay lại phòng chính"
			interaction_prompt.visible = true

# Xử lý khi người chơi rời vùng thoát
func _on_exit_area_body_exited(body):
	if body.name == "Player":
		exit_door_active = false
		if current_interactable == "exit_door":
			current_interactable = null
			if interaction_prompt:
				interaction_prompt.visible = false

# Hiển thị hướng dẫn tương tác
func _show_interaction_prompt(text):
	if interaction_prompt:
		interaction_prompt.text = text
		interaction_prompt.visible = true
	print("[SecurityRoom] " + text)

# Ẩn hướng dẫn tương tác
func _hide_interaction_prompt():
	if interaction_prompt:
		interaction_prompt.visible = false 
 
