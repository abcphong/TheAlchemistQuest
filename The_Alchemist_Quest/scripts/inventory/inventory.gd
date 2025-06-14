extends Node2D

const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/inventory_slot.gd")
@onready var inventory_slots = $GridContainer
@onready var popup_panel = $PopupPanel
@onready var popup_label = $PopupPanel/VBoxContainer/DescriptionLabel

var is_dragging := false

func _ready():
	# Kết nối các sự kiện cho các slot trong inventory
	for inv_slot in inventory_slots.get_children():
		inv_slot.gui_input.connect(slot_gui_input.bind(inv_slot))
		inv_slot.add_to_group("InventorySlot")
	initialize_inventory()
	popup_panel.hide()

func is_puzzle_ui_active() -> bool:
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if not puzzle_ui:
		puzzle_ui = get_tree().get_current_scene().find_child("puzzle_ui_task1", true, false)
	return puzzle_ui != null and puzzle_ui.visible

func initialize_inventory():
	var slots = $GridContainer.get_children()
	for i in range(slots.size()):
		slots[i].slot_index = i
		slots[i].is_hotbar_slot = false
		slots[i].add_to_group("InventorySlot")
		slots[i].gui_input.connect(slot_gui_input.bind(slots[i]))
		
		if PlayerInventory.inventory.has(i) and PlayerInventory.inventory[i] != null and PlayerInventory.inventory[i][0] != null:
			var item_name = str(PlayerInventory.inventory[i][0])
			var item_quantity = int(PlayerInventory.inventory[i][1])
			slots[i].initialize_item(item_name, item_quantity)
		else:
			slots[i].initialize_item("", 0)

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if UserInterface.holding_item == null and slot.item:
				UserInterface.holding_item = slot.pickFromSlot()
				var ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
				if ui:
					ui.add_child(UserInterface.holding_item)
				else:
					UserInterface.add_child(UserInterface.holding_item)
				UserInterface.holding_item.set_z_as_relative(false)
				UserInterface.holding_item.z_index = 9999
				UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
				UserInterface.update_held_item_visibility()
				UserInterface.is_dragging = true
		else:
			if UserInterface.holding_item:
				UserInterface.is_dragging = false
				var hovered_slot = get_slot_under_mouse()
				try_drop_item(hovered_slot, event.global_position)
	elif event is InputEventMouseMotion and is_dragging:
		if UserInterface.holding_item:
			UserInterface.holding_item.global_position = event.global_position

func get_slot_under_mouse() -> SlotClass:
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
	return null

func try_drop_item(slot: Node, mouse_pos: Vector2):
	if slot == null:
		# Kiểm tra PuzzleSlot trước
		for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
			if not puzzle_slot is Control:
				continue
			var rect := Rect2(puzzle_slot.global_position, puzzle_slot.size)
			if rect.has_point(mouse_pos):
				puzzle_slot.receive_item(UserInterface.holding_item)
				UserInterface.holding_item = null
				return
		# Nếu không phải PuzzleSlot thì vứt ra ngoài
		drop_item_to_world(UserInterface.holding_item)
		UserInterface.holding_item = null
		return

	var is_inside = slot.get_global_rect().has_point(mouse_pos)
	if is_inside:
		if !slot.item:
			left_click_empty_slot(slot)
		elif slot.item.item_name == UserInterface.holding_item.item_name:
			left_click_same_item(slot)
		else:
			left_click_different_item(null, slot)
	else:
		drop_item_to_world(UserInterface.holding_item)
		UserInterface.holding_item = null

func drop_item_to_world(item):
	item.queue_free()

func handle_right_click(event: InputEvent, slot: SlotClass):
	if is_puzzle_ui_active():
		print_debug("❌ Right click popup disabled in Puzzle UI")
		return
		
	if slot.item:
		popup_label.text = JsonData.get_item_description(slot.item.item_name)
		popup_panel.global_position = get_global_mouse_position() + Vector2(20, 20)
		popup_panel.show()
		slot.modulate = Color(1, 0.8, 0)
		await get_tree().create_timer(0.1).timeout
		slot.modulate = Color(1, 1, 1)

func show_description_popup(description: String, position: Vector2):
	if is_puzzle_ui_active():
		print_debug("❌ Description popup disabled in Puzzle UI")
		return
		
	popup_label.text = description
	popup_panel.global_position = position + Vector2(20, 20)
	popup_panel.show()

func _input(event):
	if UserInterface.holding_item:
		UserInterface.holding_item.global_position = get_global_mouse_position()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if UserInterface.holding_item:
			var hovered_slot = get_slot_under_mouse()
			try_drop_item(hovered_slot, event.global_position)

func left_click_empty_slot(slot: SlotClass):
	slot.putIntoSlot(UserInterface.holding_item)
	PlayerInventory.add_item_to_empty_slot(UserInterface.holding_item, slot)
	UserInterface.holding_item = null

func left_click_different_item(event: InputEvent, slot: SlotClass):
	PlayerInventory.remove_item(slot)
	var temp_item = slot.pickFromSlot()
	if event:
		temp_item.global_position = event.get_global_position()

	if slot.putIntoSlot(UserInterface.holding_item):
		PlayerInventory.add_item_to_empty_slot(UserInterface.holding_item, slot)
		UserInterface.holding_item = temp_item
		UserInterface.add_child(UserInterface.holding_item)
		UserInterface.holding_item.global_position = get_global_mouse_position()
		UserInterface.update_held_item_visibility()

func left_click_same_item(slot: SlotClass):
	var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
	var able_to_add = stack_size - slot.item.item_quantity
	if able_to_add >= UserInterface.holding_item.item_quantity:
		PlayerInventory.add_item_quantity(slot, UserInterface.holding_item.item_quantity)
		slot.item.add_item_quantity(UserInterface.holding_item.item_quantity)
		UserInterface.holding_item.queue_free()
		UserInterface.holding_item = null
		initialize_inventory()
	else:
		PlayerInventory.add_item_quantity(slot, able_to_add)
		slot.item.add_item_quantity(able_to_add)
		UserInterface.holding_item.decrease_item_quantity(able_to_add)
