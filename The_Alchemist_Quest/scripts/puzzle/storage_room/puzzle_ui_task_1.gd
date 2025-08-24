extends CanvasLayer
signal puzzle_solved  # 🔔 Tín hiệu thông báo puzzle đã hoàn thành
signal puzzle_closed  # 🔔 Tín hiệu thông báo puzzle đã đóng

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D

# 🎁 Phần thưởng cho người chơi (danh sách item và số lượng)
@export var reward_items: Array[String] = []
@export var reward_amounts: Array[int] = []
@export var allow_flexible_matching: bool = false

func _ready():
	layer = 5  # ✅ Set layer for consistent z-index behavior
	success_anim.visible = false
	success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))
	add_to_group("PuzzleSlot")
	
	# 🔧 FIX: Tự động hiển thị inventory để hỗ trợ drag/drop như puzzle 0
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui and ui.has_method("force_show_inventory_for_puzzle"):
		print("🔧 Storage Room Puzzle: Force showing inventory for drag/drop support")
		ui.force_show_inventory_for_puzzle()
	else:
		print("⚠️ Warning: UserInterface not found or missing force_show_inventory_for_puzzle method")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("puzzle_closed")
		_cleanup_and_close()

func _cleanup_and_close():
	"""
	Dọn dẹp và đóng puzzle UI một cách an toàn
	"""
	print("🧹 Cleaning up Storage Room Puzzle Task 1")
	
	# Ẩn inventory nếu không còn puzzle nào khác active
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui and ui.has_method("hide_inventory"):
		# Kiểm tra xem có puzzle nào khác đang active không
		var other_puzzles = get_tree().get_nodes_in_group("PuzzleSlot")
		var has_other_active_puzzles = false
		for puzzle in other_puzzles:
			if puzzle != self and puzzle.visible and is_instance_valid(puzzle):
				has_other_active_puzzles = true
				break
		
		if not has_other_active_puzzles:
			print("🧹 No other puzzles active - hiding inventory")
			ui.hide_inventory()
		else:
			print("🧹 Other puzzles still active - keeping inventory visible")
	
	queue_free()

# ✅ Kiểm tra tất cả slot đã được lắp đúng chưa
func check_all_slots_filled():
	var slots := []
	for child in get_children():
		if child is PuzzleSlot:
			slots.append(child)

	if allow_flexible_matching:
		# 🎯 Puzzle không yêu cầu đúng vị trí, chỉ cần đúng đủ item
		var required_items := []
		var filled_items := []

		for slot in slots:
			required_items += slot.expected_items
			if slot.is_filled and slot.current_item:
				filled_items.append(slot.current_item.item_name)

		required_items.sort()
		filled_items.sort()

		if required_items != filled_items:
			return
	else:
		# 🎯 Puzzle yêu cầu đúng item vào đúng slot
		for slot in slots:
			if not slot.is_filled or slot.current_item == null:
				return
			if not slot.expected_item.has(slot.current_item.item_name):
				print("❌ Slot sai:", slot.name, "| Có:", slot.current_item.item_name, "| Cần:", slot.expected_item)
				return

	# ✅ Tất cả hợp lệ
	print("➡️ Puzzle complete! Playing success animation.")
	success_anim.visible = true
	success_anim.play("finished compound")

# 🔚 Khi animation thành công kết thúc
func _on_success_anim_done():
	print("✅ SuccessAnim đã kết thúc")

	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui:
		for i in range(min(reward_items.size(), reward_amounts.size())):
			var item_name = reward_items[i]
			var qty = reward_amounts[i]
			print("🎁 Thêm vào túi:", item_name, "x", qty)
			ui.add_new_item_to_inventory(item_name, qty)
	else:
		print("❌ Không tìm thấy UserInterface để nhận item")

	# 🔔 Gửi tín hiệu cho lab_workbench
	emit_signal("puzzle_solved")

	# 🧼 Dọn giao diện sau khi hoàn tất với cleanup
	_cleanup_and_close()
