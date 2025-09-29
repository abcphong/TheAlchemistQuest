extends CanvasLayer
signal puzzle_solved  # 🔔 Gửi tín hiệu khi puzzle hoàn thành

@onready var success_anim = $SuccessAnim  # AnimatedSprite2D
@onready var phase1_slot = $Phase1Slot.get_child(0)  # Slot đầu tiên (Gas_mask)
@onready var phase2_slots = $Phase2Slots.get_children()  # 3 slot tiếp theo

@export var reward_items: Array[String] = []        # 🎁 Tên item thưởng
@export var reward_amounts: Array[int] = []         # 🎁 Số lượng tương ứng
@export var guide_dialog_key: String = "Puzzle_Guide_Introroom_Task3"
@export_file("*.json") var guide_dialog_file: String = "res://The_Alchemist_Quest/assets/json/intro_room/intro_dialoge.json"

var current_phase := 1  # Theo dõi phase hiện tại

# Thêm tham chiếu đến Inventory của puzzle để hiển thị giống Task 1/2
@onready var inventory_container := $InventoryContainer
@onready var inventory := $InventoryContainer/Inventory

func _ready():
	layer = 5  # ✅ Set layer for consistent z-index behavior
	success_anim.visible = false
	$Phase1Slot.visible = true
	$Phase2Slots.visible = false

	# Hiển thị Inventory cục bộ trong puzzle giống Task 1/2 và khởi tạo an toàn
	if inventory_container:
		inventory_container.visible = true
	if inventory:
		if not inventory.is_drag_operation_active():
			inventory.initialize_inventory()
		else:
			# Nếu đang drag, defer init để tránh xung đột
			call_deferred("_safe_init_inventory")

	# Hiển thị hướng dẫn puzzle khi mở
	if guide_dialog_file:
		DialogPlayer.set_dialog_file(guide_dialog_file)
		SignalBus.emit_signal("display_puzzle_dialog", guide_dialog_key, null)
func _safe_init_inventory():
	if inventory and not inventory.is_drag_operation_active():
		inventory.initialize_inventory()

# Helper: So khớp “mềm” tên item (chấp nhận _ và dấu cách, không phân biệt hoa thường)
func _names_match(expected_list: Array[String], actual_name: String) -> bool:
	if actual_name.is_empty():
		return false
	var norm_actual := actual_name.replace("_", " ").strip_edges().to_lower()
	for e in expected_list:
		if e == actual_name:
			return true
		var norm_e := e.replace("_", " ").strip_edges().to_lower()
		if norm_e == norm_actual:
			return true
	return false

func check_all_slots_filled():
	if current_phase == 1:
		if not phase1_slot.is_filled or not phase1_slot.current_item:
			return

		# So khớp “mềm” để tránh kẹt do khác biệt tên
		if not _names_match(phase1_slot.expected_item, phase1_slot.current_item.item_name):
			print("❌ Sai item phase 1:", phase1_slot.current_item.item_name)
			return

		print("✅ Phase 1 đúng item:", phase1_slot.current_item.item_name)
		start_phase2()

	elif current_phase == 2:
		for slot in phase2_slots:
			if not slot.is_filled or not slot.current_item:
				return
			if not _names_match(slot.expected_item, slot.current_item.item_name):
				print("❌ Slot sai:", slot.name, "| Có:", slot.current_item.item_name, "| Cần:", slot.expected_item)
				return

		print("🎉 Phase 2 hoàn tất. Bắt đầu success animation.")
		start_success_animation()

func start_phase2():
	current_phase = 2
	$Phase1Slot.visible = false
	$Phase2Slots.visible = true

	success_anim.visible = true
	success_anim.play("Have_mask")  # 🔁 Hiện frame mask

func start_success_animation():
	for slot in phase2_slots:
		slot.visible = false

	success_anim.visible = true
	success_anim.play("Completed")  # ✅ Animation hoàn thành
	success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))

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

	emit_signal("puzzle_solved")
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
