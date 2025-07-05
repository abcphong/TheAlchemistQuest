extends Node2D

@onready var hotbar = $HotbarSlot
@onready var slots = hotbar.get_children()
@onready var popup_panel = $PopupPanel
const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/inventory_slot.gd")

func _ready():
	for i in range(slots.size()):
		slots[i].slot_index = i
		slots[i].is_hotbar_slot = true
		slots[i].add_to_group("InventorySlot")
		slots[i].gui_input.connect(slot_gui_input.bind(slots[i]))
	PlayerInventory.inventory_changed.connect(initialize_hotbar)
	initialize_hotbar()

	# Ẩn PopupPanel khi khởi tạo
	if popup_panel:
		popup_panel.hide()
	
func initialize_hotbar():
	# Đầu tiên, xóa tất cả items hiện có trong slots
	for i in range(slots.size()):
		if slots[i].item:
			# Xóa item khỏi slot
			if slots[i].item:
				slots[i].item.queue_free()
				slots[i].item = null
	
	# Sau đó mới tạo lại các items từ PlayerInventory
	for i in range(slots.size()):
		if PlayerInventory.hotbar.has(i):
			var data = PlayerInventory.hotbar[i]
			if data != null and data[0] != null and str(data[0]) != "":
				slots[i].initialize_item(data[0], data[1])
			else:
				slots[i].initialize_item("", 0) # Đảm bảo slot được làm sạch

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				handle_left_click(event, slot)

func handle_left_click(event: InputEvent, slot: InventorySlot):
	var ui = get_tree().root.find_child("UserInterface", true, false)
	if ui == null:
		return
	# Currently holding an Item
	if ui.holding_item != null:
		handle_place_item(ui,slot,event)
	else:
		handle_pick_item(ui,slot)

func handle_place_item(ui,slot: InventorySlot, event: InputEvent):
	# Empty slot
	if !slot.item:
		slot.putIntoSlot(ui.holding_item)
		PlayerInventory.add_item_to_empty_slot(ui.holding_item, slot, true)
		ui.holding_item = null
		# Cập nhật lại UI
		update_ui()
	# Slot already contains an item
	else:
		# Check if valid data exists
		if slot.item == null or ui.holding_item == null:
			return
			
		# Different item, so swap
		if ui.holding_item.item_name != slot.item.item_name:
			var old_item = slot.putIntoSlot(ui.holding_item)
			PlayerInventory.add_item_to_empty_slot(ui.holding_item, slot, true)
			if old_item:
				ui.holding_item = old_item
				ui.holding_item.global_position = event.global_position
			# Cập nhật lại UI
			update_ui()
		# Same item, try to merge
		else:
			# Verify the item exists in JsonData
			if not JsonData.item_data.has(slot.item.item_name):
				return
				
			var stack_size = int(JsonData.item_data[slot.item.item_name].get("StackSize", 99))
			var able_to_add = stack_size - slot.item.item_quantity
			if able_to_add >= ui.holding_item.item_quantity:
				slot.item.add_item_quantity(ui.holding_item.item_quantity)
				PlayerInventory.add_item_quantity(slot, ui.holding_item.item_quantity, true)
				ui.holding_item.queue_free()
				ui.holding_item = null
				# Cập nhật lại UI
				update_ui()
			else:
				if able_to_add > 0:
					slot.item.add_item_quantity(able_to_add)
					PlayerInventory.add_item_quantity(slot, able_to_add, true)
					ui.holding_item.decrease_item_quantity(able_to_add)
					# Cập nhật lại UI
					update_ui()

# Hàm cập nhật lại toàn bộ UI
func update_ui():
	# Cập nhật hotbar
	initialize_hotbar()
	
	# Cập nhật inventory nếu có
	var inventory_ui = get_tree().root.find_child("Inventory", true, false)
	if inventory_ui:
		inventory_ui.initialize_inventory()

func handle_pick_item(ui,slot:InventorySlot):
	if slot.item:
		# Ghi lại thông tin về slot gốc trước khi nhấc item
		ui.original_slot_index = slot.slot_index
		ui.original_is_hotbar = true
		ui.original_puzzle_slot = null # Đảm bảo reset thông tin puzzle

		ui.holding_item = slot.pickFromSlot()
		if ui.holding_item:
			ui.add_child(ui.holding_item)
			ui.holding_item.global_position = get_viewport().get_mouse_position()
