extends Node
class_name LevelManager
static var instance: LevelManager

## ==== HỆ THỐNG NHIỆM VỤ ====
# Gán toàn bộ chuỗi nhiệm vụ của màn chơi vào đây, theo đúng thứ tự.
@export var quest_sequence: Array[QuestResource]

## ==== HỆ THỐNG MAP ====
@export_file("*.tscn") var map_name: String # Tên của map hiện tại, ví dụ "IntroRoom"

# ==== THEO DÕI TIẾN ĐỘ ====
var current_task_index: int = 0
var all_tasks_completed: bool = false
var current_quest: QuestResource = null

# ==== THAM CHIẾU ====
# QuestManager nên được đặt trong một scene Autoload hoặc một scene cố định
# để dễ dàng truy cập. Giả sử nó là con của root.

func _ready():
	instance = self
	
	# Kết nối với các tín hiệu toàn cục
	# Dòng này giờ sẽ hoạt động bình thường
	QuestManager.task_completed.connect(_on_task_completed)
	EventBus.quest_event.connect(_on_quest_event_triggered)
	
	# Bắt đầu nhiệm vụ đầu tiên
	start_new_task()
	
	# Thông báo cho EventBus biết map đã thay đổi
	# Dòng này giờ sẽ hoạt động bình thường
	EventBus.emit_signal("map_changed", map_name)
	
## === BỘ NÃO XỬ LÝ NHIỆM VỤ === ##

func start_new_task():
	if current_task_index >= quest_sequence.size():
		_complete_current_map()
		return
		
	current_quest = quest_sequence[current_task_index]
	print("▶️ Chuẩn bị cho Task %d: '%s'" % [current_task_index + 1, current_quest.quest_name])
	
	# Thông báo cho lab_workbench cập nhật puzzle hiện tại
	var workbench = get_tree().get_first_node_in_group("Workbench")
	if workbench:
		workbench.set_current_puzzle_ui(current_task_index)
	
	# Xử lý kích hoạt nhiệm vụ dựa trên loại
	match current_quest.activation_type:
		QuestResource.ActivationType.AUTO_START, QuestResource.ActivationType.MAP_ENTER:
			# Các loại này sẽ tự bắt đầu ngay lập tức
			QuestManager.start_quest(current_quest)
			
		QuestResource.ActivationType.NPC_INTERACTION:
			print("   -> Đang chờ tương tác với NPC: %s" % current_quest.npc_id)
			# Không làm gì cả, chờ NPC gọi hàm
			
		QuestResource.ActivationType.EVENT_TRIGGERED:
			print("   -> Đang chờ sự kiện: %s" % current_quest.trigger_event)
			# Không làm gì cả, chờ EventBus phát tín hiệu

	update_shelves_for_current_task()

func _on_task_completed():
	print("✅ Task %d ('%s') đã hoàn thành!" % [current_task_index + 1, current_quest.quest_name])
	
	current_task_index += 1 # 🚨 Phải tăng index trước
	# Nếu quest vừa hoàn thành có yêu cầu chuyển cảnh, thực hiện nó
	if current_quest.next_scene:
		# Trước khi chuyển cảnh, vẫn phải cập nhật shelf (để lưu trạng thái nếu cần)
		update_shelves_for_current_task()
		get_tree().change_scene_to_file(current_quest.next_scene)
		return # Dừng lại sau khi chuyển cảnh
		
# Gọi lab_workbench để chuẩn bị puzzle_ui tiếp theo
	var workbench = get_tree().get_first_node_in_group("Workbench")
	if workbench:
		workbench.set_current_puzzle_ui(current_task_index)

	# Nếu không chuyển cảnh, vẫn update shelf trước khi chuyển task
	update_shelves_for_current_task()
	# Chuyển sang nhiệm vụ tiếp theo trong chuỗi
	start_new_task()


## === XỬ LÝ CÁC TÁC NHÂN BÊN NGOÀI === ##
func _on_quest_event_triggered(event_name: String):
	if event_name == "PUZZLE_%d_COMPLETED" % (current_task_index + 1):
		print("🧩 Nhận tín hiệu puzzle hoàn thành -> Hoàn thành task.")
		_on_task_completed()
		return
	
	# Kiểm tra xem quest hiện tại có đang chờ sự kiện này không
	if (current_quest and 
		current_quest.activation_type == QuestResource.ActivationType.EVENT_TRIGGERED and
		current_quest.trigger_event == event_name):
		
		print("⚡ Sự kiện '%s' đã kích hoạt nhiệm vụ!" % event_name)
		QuestManager.start_quest(current_quest)

func interact_with_npc(npc_id: String):
	# Kiểm tra xem quest hiện tại có đang chờ NPC này không
	if current_task_index < quest_sequence.size():
		var current_quest = quest_sequence[current_task_index] 
		if current_quest.activation_type == QuestResource.ActivationType.NPC_INTERACTION and current_quest.npc_id == npc_id:
			print("👤 NPC '%s' đã kích hoạt nhiệm vụ!" % npc_id)
			QuestManager.start_quest(current_quest)

func _complete_current_map():
	all_tasks_completed = true
	print("🎉 Đã hoàn thành tất cả nhiệm vụ trong map '%s'" % map_name)

func update_shelves_for_current_task():
	# +1 vì task_number thường bắt đầu từ 1, còn index bắt đầu từ 0
	var task_number_for_shelf = current_task_index + 1
	var shelves = get_tree().get_nodes_in_group("Shelf") # Sửa lại tên group nếu cần
	for shelf in shelves:
		if shelf.has_method("setup_for_task"):
			shelf.setup_for_task(task_number_for_shelf)
	print("Đã cập nhật tủ đồ cho Task %d" % task_number_for_shelf)
