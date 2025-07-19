extends CanvasLayer

signal puzzle_closed
@export var dialog_key = "Player_finished_introRoom_Task1"
@export_file("*.json") var dialog_file

@onready var success_anim = $SuccessAnim  # Optional: add a success animation node if you want
@onready var inventory = $InventoryContainer/Inventory

# THÊM MỚI: Biến trạng thái để đảm bảo sequence chỉ chạy 1 lần
var puzzle_solved := false


func _ready():
	print("🔵 Puzzle UI Task 1 initializing")
	if has_node("SuccessAnim"):
		success_anim.visible = false
	add_to_group("PuzzleSlot")
	
	# Ensure inventory is properly initialized
	if inventory:
		print("✅ Initializing puzzle inventory")
		inventory.initialize_inventory()
		
		# Connect to inventory update signal
		inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	else:
		print("❌ No inventory node found")

func _on_inventory_updated():
	print("🔵 Inventory updated, refreshing display")
	# Chỉ cập nhật UI nhẹ nhàng, KHÔNG gọi lại initialize_inventory()
	# Ví dụ: cập nhật label, hiệu ứng, kiểm tra slot...
	check_all_slots_filled()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("🔵 Closing puzzle UI")
		queue_free()

func check_all_slots_filled():
	
	# 1. Guard Clause: Nếu puzzle đã được giải, không làm gì cả
	if puzzle_solved:
		return
		
	for child in get_children():
		if child is PuzzleSlot and not child.is_filled:
			return # Vẫn còn slot trống, thoát ra
	
	# 3. Bắt đầu chuỗi sự kiện khi puzzle được giải
	puzzle_solved = true # Đặt cờ ngay lập tức để tránh lặp lại
	print("✅ Puzzle đã được giải! Bắt đầu chuỗi sự kiện hoàn thành.")
	# ---- HÀNH ĐỘNG TỨC THÌ ----
	# Chạy animation thành công
	if has_node("SuccessAnim"):
		success_anim.visible = true
		success_anim.play("complete")
	# Hiển thị dialog
	if dialog_file:
			DialogPlayer.set_dialog_file(dialog_file)
			SignalBus.emit_signal("display_dialog", dialog_key)
	# Báo cho QuestManager là đã "đạt được mục tiêu"
	if QuestManager:
		QuestManager.reach_goal()
		print("   -> Đã báo 'reach_goal' cho QuestManager.")
	# HOÀN THÀNH NHIỆM VỤ NGAY LẬP TỨC để kích hoạt task tiếp theo
	EventBus.emit_signal("quest_event", "PUZZLE_1_COMPLETED")
		
	# ---- HÀNH ĐỘNG DELAY ----
	
	print("⏳ Đang chờ 5 giây trước khi đóng UI...")
	await get_tree().create_timer(5.0).timeout # Chờ 5 giây

	# ---- HÀNH ĐỘNG CUỐI CÙNG ----
	
	print("⏰ Hết thời gian chờ. Đóng UI puzzle.")
	# Tự động đóng UI puzzle sau khi hoàn tất
	emit_signal("puzzle_closed")
	queue_free()
