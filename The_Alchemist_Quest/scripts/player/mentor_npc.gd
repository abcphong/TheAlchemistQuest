extends Area2D
class_name MentorNPC

# ID này phải khớp với npc_id trong file .tres của Trial Quest
@export var npc_id: String = "mentor"
@export var dialog_key: String = "Mentor"
@export_file("*.json") var dialog_file
@export var quest_data: QuestResource

@onready var exclamination_mark = $exclamination_mark
var dialog_stage = 0

var player_in_area = false

func _ready() -> void:
	print("🛠 Mentor NPC Ready - Dialog Key: '" + dialog_key + "'")
	if quest_data and quest_data.show_marker:
		exclamination_mark.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": # Kiểm tra bằng group an toàn hơn
		player_in_area = true
		interact()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = false

# Gọi hàm này khi người chơi nhấn nút tương tác

func interact():
	if not player_in_area: return
	var current_key = dialog_key + "_" + str(dialog_stage + 1)
	# Hiển thị dialog
	if DialogPlayer:
		DialogPlayer.set_dialog_file(dialog_file)
		SignalBus.emit_signal("display_dialog", current_key, self)
	
	# Yêu cầu LevelManager bắt đầu nhiệm vụ của nó
	# Bắt đầu nhiệm vụ nếu có
	if quest_data:
		QuestManager.start_quest(quest_data)
		exclamination_mark.visible = false  # Ẩn marker sau khi nhận quest
