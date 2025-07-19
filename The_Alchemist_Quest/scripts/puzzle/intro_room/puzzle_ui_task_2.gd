extends CanvasLayer

@onready var slot_container = $InventoryContainer/Inventory/GridContainer
@onready var success_anim = $SuccessAnim  # Optional: add a success animation node if you want
var inventory_ref = null

func _ready():
	if has_node("SuccessAnim"):
		success_anim.visible = false
	add_to_group("PuzzleSlot")

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
