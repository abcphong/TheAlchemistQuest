extends Node2D  # hoặc Node/Control gì đó, miễn là một node

@onready var lighting_system = $DynamicLighting
@onready var level_manager = LevelManager.instance

var dialog_stage = 0
var current_dialog =""

func _ready():
	var inv = $UserInterface/Inventory
	UserInterface.inventory_node = inv

	# Initialize lighting system
	if lighting_system:
		# Giữ cấu hình màu, bán kính, offset như bạn muốn
		lighting_system.set_light_radius(50.0)  # đèn pin nhỏ khi mất điện
		lighting_system.set_light_color(Color(1, 0.95, 0.9))  # ánh sáng ấm
		# Không set set_darkness ở đây nữa, để apply theo trạng thái điện
		lighting_system.light_offset = Vector2(0, -10)

		# Áp trạng thái điện ban đầu theo GameManager.power_state
		var gm = get_node_or_null("/root/GameManager")
		var is_power_on := false
		if gm and gm.get("power_state") != null and gm.power_state.has("is_power_on"):
			is_power_on = gm.power_state["is_power_on"]
		lighting_system.apply_power_state(is_power_on)

		# Lắng nghe load game để áp lại trạng thái điện sau khi load
		var save_load_manager = get_node_or_null("/root/SaveLoadManager")
		if save_load_manager and not save_load_manager.is_connected("game_loaded", Callable(self, "_on_game_loaded")):
			save_load_manager.connect("game_loaded", Callable(self, "_on_game_loaded"))

		# Lắng nghe khi giải xong Puzzle 1 để bật điện
		if EventBus and not EventBus.quest_event.is_connected(_on_quest_event_triggered):
			EventBus.quest_event.connect(_on_quest_event_triggered)

		if DialogPlayer:
			DialogPlayer.connect("dialog_finished", _on_dialog_finished)
			show_dialog("Player_1")
	
	# Đảm bảo LevelManager đã khởi tạo quest
	if LevelManager.instance and LevelManager.instance.current_quest:
		_initialize_intro_quest()
	else:
		print("❌ Lỗi: LevelManager chưa được khởi tạo.")

	
func _initialize_intro_quest():
	var intro_quest = level_manager.quest_sequence[0]
	
	# Kiểm tra nếu quest chưa được bắt đầu
	if QuestManager.quest_status == QuestManager.QuestStatus.INACTIVE:
		QuestManager.start_quest(intro_quest)
		# Gọi setup cho shelf
		var shelf = get_node("Shelf")
		shelf.setup_for_task(1)
		level_manager.update_shelves_for_current_task()
		
	# Hoặc nếu quest đang trong trạng thái STARTED nhưng UI bị ẩn
	elif QuestManager.quest_status == QuestManager.QuestStatus.STARTED and !QuestManager.QuestBox.visible:
		QuestManager.QuestBox.visible = true

func show_dialog(key: String):
	if DialogPlayer and not DialogPlayer.in_progress:
		DialogPlayer.set_dialog_file("res://The_Alchemist_Quest/assets/json/intro_room/intro_dialoge.json")
		SignalBus.emit_signal("display_dialog", key, null)
		current_dialog = key
		print("Showing dialog:", key)

func _on_dialog_finished():
	print("Dialog finished for:", current_dialog)
	match current_dialog:
		"Player_1":
			show_dialog("AI quản lý_1")
		"AI quản lý_1":
			# Now you can enable player item pickup or next steps
			print("AI quản lý_1 dialog finished, ready for player actions")
			current_dialog = ""
		_:
			current_dialog = ""
			
func on_player_pickup(item_name: String):
	var dialog_key = ""
	match item_name:
		"Cu":
			dialog_key = "Player_pickup_cu"
		"Zn":
			dialog_key = "Player_pickup_zn"
		# Add more items as needed
	if dialog_key != "":
		show_dialog(dialog_key)

func _on_game_loaded():
	# Sau khi load, áp lại trạng thái điện
	var gm = get_node_or_null("/root/GameManager")
	var is_power_on := false
	if gm and gm.get("power_state") != null and gm.power_state.has("is_power_on"):
		is_power_on = gm.power_state["is_power_on"]
	if lighting_system:
		lighting_system.apply_power_state(is_power_on)

func _on_quest_event_triggered(event_name: String):
	# Khi hoàn thành Puzzle 1 -> bật điện trở lại
	if event_name == "PUZZLE_1_COMPLETED":
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.power_state["is_power_on"] = true
		if lighting_system:
			lighting_system.power_restore_on()


func _on_health_timer_timeout() -> void:
	pass # Replace with function body.
