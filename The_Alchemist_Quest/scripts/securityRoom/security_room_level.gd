extends Node2D

# Tham chiếu đến các node tương tác
@onready var ventilation_fan = get_node_or_null("SecurityRoomInterior/Decor/VentilationFan")
@onready var red_beacon = get_node_or_null("SecurityRoomInterior/Decor/RedBeacon")
@onready var exit_area = get_node_or_null("SecurityRoomInterior/Door/ExitArea")
@onready var monitor_interaction = get_node_or_null("SecurityRoomInterior/InteractionPoints/MonitorInteraction")
@onready var cabinet_interaction = get_node_or_null("SecurityRoomInterior/InteractionPoints/CabinetInteraction")
@onready var interaction_prompt = get_node_or_null("SecurityRoomInterior/InteractionPrompt")
@onready var player = get_node_or_null("BaseLevel/Player")
@onready var spawn_point = get_node_or_null("SecurityRoomInterior/SpawnPoint")
@onready var door_sprite = get_node_or_null("SecurityRoomInterior/Door/DoorSprite")

# Đường dẫn đến scene giao diện màn hình giám sát
const SECURITY_MONITOR_UI_PATH = "res://The_Alchemist_Quest/scences/puzzle/security_room/security_monitor_ui.tscn"

# Biến theo dõi trạng thái
var player_in_monitor_area = false
var player_in_cabinet_area = false
var player_in_exit_area = false
var exit_door_active = false
var monitor_ui_active = false

# Vị trí cửa trong scene gốc
const SECURITY_DOOR_POSITION = Vector2(2043, 744)
const GAME_SCENE_PATH = "res://The_Alchemist_Quest/scences/game.tscn"

# Tham chiếu đến player
var current_interactable = null

func _ready():
	# Tham chiếu đến health_bar từ base_level
	var health_bar = get_node_or_null("BaseLevel/UI/HealthBar")

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

	if ventilation_fan:
		ventilation_fan.play("default")
		ventilation_fan.speed_scale = 1.0

	if red_beacon:
		red_beacon.play("default")
		red_beacon.speed_scale = 0.5

	if interaction_prompt:
		interaction_prompt.visible = false

	if player and spawn_point:
		player.global_position = spawn_point.global_position
		print("[SecurityRoom] Đã đặt player tại điểm spawn")
		
		if health_bar and player.has_node("AnimatedSprite2D"):
			# health_bar đã được quản lý bởi base_level.tscn
			print("[SecurityRoom] HealthBar được quản lý bởi BaseLevel.")
			health_bar.load_health_state()
			print("[SecurityRoom] Đã tải trạng thái thanh máu")

	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)

	print("[SecurityRoom] Phòng bảo mật đã khởi tạo")

func save_state() -> Dictionary:
	return {"exit_door_active": exit_door_active}

func load_state(state: Dictionary):
	if state.has("exit_door_active"):
		exit_door_active = state["exit_door_active"]

func get_saveable_id() -> String:
	return "security_room_manager"

func _process(delta):
	if current_interactable and Input.is_action_just_pressed("interact"):
		match current_interactable:
			"monitor": _handle_monitor_interaction()
			"cabinet": _handle_cabinet_interaction()
			"exit_door": _exit_room()

	if exit_door_active and Input.is_action_just_pressed("interact"):
		_exit_room()

func _handle_monitor_interaction():
	if monitor_ui_active: return
	var monitor_ui_scene = load(SECURITY_MONITOR_UI_PATH)
	if monitor_ui_scene:
		var monitor_ui = monitor_ui_scene.instantiate()
		add_child(monitor_ui)
		monitor_ui_active = true
		monitor_ui.tree_exited.connect(func(): monitor_ui_active = false)

func _handle_cabinet_interaction():
	print("[SecurityRoom] Tương tác với tủ hóa chất")

func _exit_room():
	var game_manager = get_node_or_null("/root/GameManager")
	var return_position = SECURITY_DOOR_POSITION
	if game_manager and game_manager.security_door_entry_position != Vector2.ZERO:
		return_position = game_manager.security_door_entry_position

	if game_manager:
		game_manager.save_player_position(return_position, "security_room")
		game_manager.player_spawn_data["from_security_room"] = true

	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").persist_state_for_transition()

	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_monitor_interaction_body_entered(body):
	if body.is_in_group("Player"):
		current_interactable = "monitor"
		_show_interaction_prompt("Nhấn E để kiểm tra màn hình")

func _on_interaction_body_exited(body):
	if body.is_in_group("Player"):
		current_interactable = null
		if interaction_prompt: interaction_prompt.visible = false

func _on_cabinet_interaction_body_entered(body):
	if body.is_in_group("Player"):
		current_interactable = "cabinet"
		_show_interaction_prompt("Nhấn E để mở tủ hóa chất")

func _on_exit_area_body_entered(body):
	if body.is_in_group("Player"):
		exit_door_active = true
		current_interactable = "exit_door"
		_show_interaction_prompt("Nhấn E để quay lại phòng chính")

func _on_exit_area_body_exited(body):
	if body.is_in_group("Player"):
		exit_door_active = false
		if current_interactable == "exit_door":
			current_interactable = null
			if interaction_prompt: interaction_prompt.visible = false

func _show_interaction_prompt(text):
	if interaction_prompt:
		interaction_prompt.text = text
		interaction_prompt.visible = true 
