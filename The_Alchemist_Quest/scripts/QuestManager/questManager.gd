extends CanvasLayer

signal task_completed

# Các biến UI giữ nguyên, chúng sẽ hoạt động vì giờ cấu trúc đã đúng
@onready var QuestBox: CanvasLayer = $QuestBox
@onready var QuestTitle: RichTextLabel = $QuestBox/QuestTitle
@onready var QuestDescription: RichTextLabel = $QuestBox/QuestDescription

enum QuestStatus { INACTIVE, STARTED, GOAL_REACHED, FINISHED }
var quest_status: QuestStatus = QuestStatus.INACTIVE
var active_quest_data: QuestResource = null

func _ready():
	# Kiểm tra lỗi một cách an toàn
	if QuestBox == null:
		print("LỖI: QuestManager (Autoload) không tìm thấy node con 'QuestBox'. Hãy đảm bảo cấu trúc scene là chính xác.")
		return

	QuestBox.visible = false
	layer = 100

		
# Hàm này chỉ nhận lệnh từ LevelManager hoặc các hệ thống khác
func start_quest(quest_data: QuestResource):
	if not quest_data: return
	
	active_quest_data = quest_data
	quest_status = QuestStatus.STARTED
	
	if QuestBox:
		QuestBox.visible = true
		QuestTitle.text = quest_data.quest_name
		QuestDescription.text = quest_data.quest_description
		
	print("UI Hiển thị nhiệm vụ: %s" % quest_data.quest_name)

func reach_goal():
	if quest_status != QuestStatus.STARTED: return
	quest_status = QuestStatus.GOAL_REACHED
	
	if QuestDescription:
		QuestDescription.text = active_quest_data.reached_goal_text

func complete_current_task():
	if quest_status != QuestStatus.GOAL_REACHED: return
	
	quest_status = QuestStatus.FINISHED
	
	if QuestBox:
		QuestBox.visible = false
		
	print("UI Báo cáo nhiệm vụ '%s' hoàn thành." % active_quest_data.quest_name)
	
	emit_signal("task_completed")
