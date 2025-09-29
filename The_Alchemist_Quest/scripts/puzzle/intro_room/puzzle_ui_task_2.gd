extends CanvasLayer
signal puzzle_solved  # 🔔 Thêm signal để báo puzzle hoàn thành

@onready var slot_container = $InventoryContainer/Inventory/GridContainer
@onready var success_anim = $SuccessAnim  # Optional: add a success animation node if you want
var inventory_ref = null
@export var guide_dialog_key: String = "Puzzle_Guide_Introroom_Task2"
@export_file("*.json") var guide_dialog_file: String = "res://The_Alchemist_Quest/assets/json/intro_room/intro_dialoge.json"

func _ready():
	layer = 5  # ✅ Set layer for consistent z-index behavior
	if has_node("SuccessAnim"):
		success_anim.visible = false
		# Kết nối khi animation kết thúc để emit puzzle_solved
		if not success_anim.is_connected("animation_finished", Callable(self, "_on_success_anim_done")):
			success_anim.connect("animation_finished", Callable(self, "_on_success_anim_done"))
	add_to_group("PuzzleSlot")

	# Hiển thị hướng dẫn puzzle khi mở
	if guide_dialog_file:
		DialogPlayer.set_dialog_file(guide_dialog_file)
		SignalBus.emit_signal("display_puzzle_dialog", guide_dialog_key, null)
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		

func check_all_slots_filled():
	for child in get_children():
		if child is PuzzleSlot and not child.is_filled:
			return
	if has_node("SuccessAnim"):
		success_anim.visible = true
		success_anim.play("complete")
	else:
		# Không có animation -> emit ngay
		emit_signal("puzzle_solved")
		queue_free()
		
# Hàm nhận inventory từ player
func set_inventory(inventory_data):
	inventory_ref = inventory_data
	update_ui()

# Hàm cập nhật giao diện inventory
func update_ui():
	if inventory_ref == null:
		print("⚠️ Chưa có inventory để hiển thị.")
		return

	var slots = slot_container.get_children()

	for i in range(slots.size()):
		var slot = slots[i]
		if slot.has_method("set_inventory_reference"):
			slot.slot_index = i
			slot.set_inventory_reference(inventory_ref)
		
		if i < inventory_ref.size() and inventory_ref[i] != null:
			var item_data = inventory_ref[i]
			if item_data[0] != null and item_data[1] > 0:
				slot.initialize_item(item_data[0], item_data[1])
			else:
				slot.initialize_item("", 0)
		else:
			slot.initialize_item("", 0)

func _on_success_anim_done():
	# Khi animation complete, báo hoàn thành cho lab_workbench
	emit_signal("puzzle_solved")
	queue_free()
