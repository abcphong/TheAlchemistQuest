extends CanvasLayer

signal puzzle_closed
@export var dialog_key = "Player_finished_introRoom_Task1"
@export_file("*.json") var dialog_file

@onready var success_anim = $SuccessAnim  # Optional: add a success animation node if you want
@onready var inventory = $InventoryContainer/Inventory

# THÊM MỚI: Biến trạng thái để đảm bảo sequence chỉ chạy 1 lần
var puzzle_solved := false
@export var guide_dialog_key: String = "Puzzle_Guide_Introroom_Task1"
@export_file("*.json") var guide_dialog_file: String = "res://The_Alchemist_Quest/assets/json/intro_room/intro_dialoge.json"

func _ready():
	layer = 5  # ✅ Set layer to match Puzzle 0 for consistent z-index behavior
	print("🔵 Puzzle UI Task 1 initializing with layer =", layer)
	if has_node("SuccessAnim"):
		success_anim.visible = false
	add_to_group("PuzzleSlot")
	
	# Hiển thị hướng dẫn puzzle khi mở
	if guide_dialog_file:
		DialogPlayer.set_dialog_file(guide_dialog_file)
		SignalBus.emit_signal("display_puzzle_dialog", guide_dialog_key, null)

	# SAFE inventory initialization - avoid destructive operations during drag
	if inventory:
		print("✅ Connecting to puzzle inventory safely")

		# Connect to inventory update signal
		if not inventory.is_connected("inventory_updated", Callable(self, "_on_inventory_updated")):
			inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))

		# Only initialize if no drag operations are active
		if not inventory.is_drag_operation_active():
			print("✅ Safe to initialize inventory - no drag operations active")
			inventory.initialize_inventory()
		else:
			print("⚠️ Skipping inventory initialization - drag operation in progress")
			# Defer initialization until drag operation completes
			_defer_inventory_initialization()
	else:
		print("❌ No inventory node found")

func _on_inventory_updated():
	# Chỉ cập nhật UI nhẹ nhàng, KHÔNG gọi lại initialize_inventory()
	# Ví dụ: cập nhật label, hiệu ứng, kiểm tra slot...
	check_all_slots_filled()

func _defer_inventory_initialization():
	# Wait for drag operations to complete before initializing

	# Check periodically if drag operations have finished
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(_check_drag_completion)
	add_child(timer)
	timer.start()

func _check_drag_completion():
	if inventory and not inventory.is_drag_operation_active():
		inventory.initialize_inventory()

		# Remove the timer
		for child in get_children():
			if child is Timer:
				child.queue_free()
				break

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("puzzle_closed")
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
