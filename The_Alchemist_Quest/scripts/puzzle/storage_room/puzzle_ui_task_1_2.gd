extends CanvasLayer
signal puzzle_solved  # 🔔 Tín hiệu thông báo puzzle đã hoàn thành

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D

# 🎁 Phần thưởng cho người chơi (danh sách item và số lượng)
@export var reward_items: Array[String] = []
@export var reward_amounts: Array[int] = []
@export var allow_flexible_matching: bool = false

func _ready():
	success_anim.visible = false
	success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))
	add_to_group("PuzzleSlot")

	# Debug log cho phần thưởng
	print("[DEBUG-REWARDS] Puzzle UI khởi tạo với phần thưởng: ", reward_items, " x ", reward_amounts)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
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
				print("[DEBUG-REWARDS] Slot sai:", slot.name, "| Có:", slot.current_item.item_name, "| Cần:", slot.expected_item)
				return

	# ✅ Tất cả hợp lệ
	print("[DEBUG-REWARDS] Puzzle hoàn thành! Phát animation thành công.")
	success_anim.visible = true
	success_anim.play("melted lock")

# 🔚 Khi animation thành công kết thúc
func _on_success_anim_done():
	print("[DEBUG-REWARDS] Animation thành công đã kết thúc")

	var ui = get_tree().get_first_node_in_group("UserInterface")
	print("[DEBUG-REWARDS] UserInterface tìm thấy: ", ui != null)
	
	if ui:
		print("[DEBUG-REWARDS] Chuẩn bị thêm ", reward_items.size(), " items vào inventory")
		for i in range(min(reward_items.size(), reward_amounts.size())):
			var item_name = reward_items[i]
			var qty = reward_amounts[i]
			print("[DEBUG-REWARDS] Thêm vào túi: ", item_name, " x ", qty)
			var success = ui.add_new_item_to_inventory(item_name, qty)
			print("[DEBUG-REWARDS] Kết quả thêm item ", item_name, ": ", success)
	else:
		print("[DEBUG-REWARDS] Không tìm thấy UserInterface để nhận item")

	# 🔔 Gửi tín hiệu cho lab_workbench
	print("[DEBUG-REWARDS] Phát tín hiệu puzzle_solved")
	emit_signal("puzzle_solved")

	# 🧼 Dọn giao diện sau khi hoàn tất
	print("[DEBUG-REWARDS] Dọn dẹp UI puzzle")
	queue_free()
