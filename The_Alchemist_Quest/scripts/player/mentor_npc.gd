extends Area2D
class_name MentorNPC

@export var npc_id: String = "mentor"
@export var dialog_key: String = "Mentor"
@export_file("*.json") var dialog_file
@export var quest_data: QuestResource
@export var repeatable_dialog: bool = true
@export var max_dialog_stages: int = 1  # Chỉ có 1 dialog duy nhất

@onready var exclamination_mark = $exclamination_mark
var dialog_stage = 0
var player_in_area = false
var quest_started = false
var available_dialogs = []  # Danh sách dialog có sẵn
var dialog_shown = false  # Đã hiện dialog chưa

func _ready() -> void:
	print("🛠 Mentor NPC Ready - Dialog Key: '" + dialog_key + "'")
	
	# Load và kiểm tra available dialogs
	load_available_dialogs()
	
	if quest_data and quest_data.show_marker:
		exclamination_mark.visible = true
	
	# Connect signals
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	
	# Connect signal để lắng nghe khi dialog kết thúc
	if SignalBus.has_signal("dialog_finished"):
		SignalBus.connect("dialog_finished", _on_dialog_finished)

func load_available_dialogs():
	# Đọc file dialog để xem có những key nào
	if dialog_file:
		var file = FileAccess.open(dialog_file, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var json = JSON.new()
			var error = json.parse(content)
			if error == OK:
				var dialog_data = json.get_data()
				for key in dialog_data.keys():
					if key.begins_with(dialog_key + "_"):
						available_dialogs.append(key)
				available_dialogs.sort()  # Sắp xếp theo thứ tự
				print("📋 Available dialogs for", npc_id, ":", available_dialogs)
			file.close()

func _input(event):
	# Không cần xử lý input vì dialog chỉ hiện 1 lần
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = true
		
		# Chỉ hiện dialog 1 lần duy nhất khi vào area
		if not dialog_shown:
			interact()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = false
		hide_interaction_hint()

func interact():
	if dialog_shown or DialogPlayer.in_progress: 
		return
	
	var current_key = dialog_key + "_1"  # Luôn dùng Mentor_1
	
	print("🗣️ Mentor interact - Key:", current_key)
	
	# Hiển thị dialog
	if DialogPlayer:
		DialogPlayer.set_dialog_file(dialog_file)
		DialogPlayer.set_repeatable_mode(false)  # Không lặp lại
		SignalBus.emit_signal("display_dialog", current_key, self)
		dialog_shown = true  # Đánh dấu đã hiện dialog
	
	# Bắt đầu quest
	if quest_data and not quest_started:
		QuestManager.start_quest(quest_data)
		quest_started = true
		print("🎯 Quest started for:", quest_data.quest_name)

# Hàm mới: xử lý khi dialog kết thúc
func _on_dialog_finished(dialog_key_finished: String, npc_source):
	# Kiểm tra xem dialog vừa kết thúc có phải của mentor này không
	if npc_source == self and dialog_key_finished.begins_with(dialog_key):
		print("✅ Dialog finished for mentor, hiding exclamation mark")
		if exclamination_mark:
			exclamination_mark.visible = false

func show_interaction_hint():
	# Không cần hint vì dialog chỉ hiện 1 lần tự động
	pass

func hide_interaction_hint():
	# Không cần hide hint
	pass

func advance_dialog_stage():
	# Chỉ advance nếu còn dialog available
	var next_stage = dialog_stage + 2  # +2 vì dialog_stage bắt đầu từ 0, dialog key từ 1
	var next_key = dialog_key + "_" + str(next_stage)
	
	if available_dialogs.has(next_key):
		dialog_stage += 1
		print("➡️ Mentor dialog advanced to stage:", dialog_stage + 1)
		
		if exclamination_mark and dialog_stage == 1:
			exclamination_mark.visible = true
	else:
		print("⚠️ No more dialog stages available. Current max:", available_dialogs.size())

func set_dialog_stage(stage: int):
	# Đảm bảo stage không vượt quá số dialog có sẵn
	var max_stage = available_dialogs.size() - 1
	if stage <= max_stage:
		dialog_stage = stage
		print("📝 Mentor dialog set to stage:", dialog_stage + 1)
	else:
		print("⚠️ Cannot set stage", stage + 1, "- max available:", max_stage + 1)

# Hàm để reload dialogs (hữu ích khi update file JSON)
func reload_dialogs():
	available_dialogs.clear()
	load_available_dialogs()
