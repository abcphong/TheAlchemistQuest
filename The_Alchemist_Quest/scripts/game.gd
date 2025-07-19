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
		# Set initial lighting parameters
		lighting_system.set_light_radius(50.0)  # Even smaller light radius
		lighting_system.set_light_color(Color(1, 0.95, 0.9))  # Very slight warm tint
		lighting_system.set_darkness(0.0)  # Almost no global darkness, just the light effect
		lighting_system.light_offset = Vector2(0, -10) # Adjust light position slightly upwards
		
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
