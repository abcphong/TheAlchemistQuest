extends Node
class_name InventorySystem

const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/slot.gd")
@onready var inventory_slots = $GridContainer
@onready var popup_panel = $PopupPanel
@onready var popup_label = $PopupPanel/VBoxContainer/DescriptionLabel
@onready var item_name_label = $PopupPanel/VBoxContainer/ItemNameLabel
@onready var item_image_rect = $PopupPanel/VBoxContainer/ItemImageRect
@onready var dragging_layer = get_tree().get_current_scene().get_node("DraggingLayer")

# State variables
var is_dragging := false
var is_initialized := false
var is_updating := false
var is_puzzle_interaction := false

# Signal declarations
signal inventory_updated
signal item_added(item_data: Dictionary)
signal item_removed(item_id: String)

func _ready():
	if not is_initialized:
		initialize_inventory_system()
		connect_signals()
		#Thêm connection vào
		PlayerInventory.connect("inventory_changed",Callable(self,"clear_ui_inventory"))

func initialize_inventory_system():
	for inv_slot in inventory_slots.get_children():
		inv_slot.gui_input.connect(slot_gui_input.bind(inv_slot))
		inv_slot.add_to_group("InventorySlot")
		inv_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	
	popup_panel.hide()
	popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_initialized = true

func connect_signals():
	if PlayerInventory.has_signal("inventory_updated"):
		PlayerInventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	PlayerInventory.inventory_changed.connect(initialize_inventory)

func _on_inventory_updated():
	if not is_updating:
		initialize_inventory()

func initialize_inventory():
	if is_updating:
		return
	
	is_updating = true
	var slots = inventory_slots.get_children()
	
	# Clear existing items first
	for slot in slots:
		if slot.item:
			slot.item.queue_free()
			slot.item = null

	# Reinitialize slots with current inventory data
	for i in range(slots.size()):
		var slot = slots[i]
		slot.slot_index = i
		slot.is_hotbar_slot = false
		
		# Truyền inventory gốc cho từng slot
		slot.set_inventory_reference(PlayerInventory.inventory)
		
		if PlayerInventory.inventory.has(i) and PlayerInventory.inventory[i] != null:
			var item_name = str(PlayerInventory.inventory[i][0])
			var item_quantity = int(PlayerInventory.inventory[i][1])
			slot.initialize_item(item_name, item_quantity)
		else:
			slot.initialize_item("", 0)
	
	is_updating = false
	emit_signal("inventory_updated")

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton:
		handle_mouse_button_event(event, slot)
	elif event is InputEventMouseMotion and is_dragging:
		handle_mouse_motion(event)

func handle_mouse_button_event(event: InputEvent, slot: SlotClass):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag_item(slot)
		else:
			end_drag_item(event.global_position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		show_item_description(slot)
		get_viewport().set_input_as_handled()
		
func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()

func start_drag_item(slot: SlotClass):
	if UserInterface.holding_item == null and slot.item:
		UserInterface.holding_item = slot.pickFromSlot()
		UserInterface.original_slot_index = slot.slot_index
		UserInterface.original_is_hotbar = slot.is_hotbar_slot
		
		if dragging_layer:
			dragging_layer.add_child(UserInterface.holding_item)
		else:
			UserInterface.add_child(UserInterface.holding_item)
		
		UserInterface.holding_item.z_index = 9999
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
		is_dragging = true
		UserInterface.is_dragging = true

func end_drag_item(mouse_pos: Vector2):
	if UserInterface.holding_item:
		is_dragging = false
		UserInterface.is_dragging = false
		var hovered_slot = get_slot_under_mouse()
		try_drop_item(hovered_slot, mouse_pos)

func get_slot_under_mouse() -> SlotClass:
	# Check puzzle UI first if active
	if is_puzzle_ui_active():
		return null
		
	# Then check inventory slots
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
	return null

func is_puzzle_ui_active() -> bool:
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if puzzle_ui and puzzle_ui.visible:
		return true
		
	var puzzle_slots = get_tree().get_nodes_in_group("PuzzleSlot")
	for slot in puzzle_slots:
		if slot.visible and is_instance_valid(slot) and slot.is_inside_tree():
			return true
	return false

func try_drop_item(slot: Node, mouse_pos: Vector2):
	#Gộp cả puzzleslot  và puzzleslottrial vào chung 1 vòng lặp
	var puzzle_slots = []
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlotTrial")
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlot")
	# Puzzle slot handling
	for puzzle_slot in puzzle_slots:
		if puzzle_slot is Control and Rect2(puzzle_slot.global_position, puzzle_slot.size).has_point(mouse_pos):
			if puzzle_slot.has_method("process_drop"):
				handle_puzzle_drop(puzzle_slot)
			else:
				puzzle_slot.receive_item(UserInterface.holding_item)
				UserInterface.holding_item = null
			cleanup_after_drop()
			return


	# Inventory slot handling (combined logic)
	if slot is SlotClass and slot.get_global_rect().has_point(mouse_pos):
		handle_inventory_drop(slot)
	else:
		# Snap item back to original slot instead of dropping to world
		print("[DEBUG-SNAP] Item dropped outside valid zones, snapping back to original slot")
		snap_item_back_to_original_slot()
		return

	# DỌN DẸP SAU KHI DROP/SWAP HOÀN TẤT
	if not is_instance_valid(UserInterface.holding_item):
		cleanup_after_drop()


func handle_puzzle_drop(puzzle_slot: Node):
	var held_item = UserInterface.holding_item
	if held_item and puzzle_slot.has_method("process_drop"):
		puzzle_slot.process_drop(held_item, get_viewport().get_mouse_position())
		is_puzzle_interaction = true
		held_item.queue_free()
		is_puzzle_interaction = false

func handle_inventory_drop(slot: SlotClass):
	if not slot.item:
		left_click_empty_slot(slot)
	elif slot.item.item_name == UserInterface.holding_item.item_name:
		left_click_same_item(slot)
	else:
		left_click_different_item(null, slot)

func snap_item_back_to_original_slot():
	if not UserInterface.holding_item or not is_instance_valid(UserInterface.holding_item):
		cleanup_after_drop()
		return

	var item = UserInterface.holding_item
	var original_index = UserInterface.original_slot_index
	var is_from_hotbar = UserInterface.original_is_hotbar
	var original_puzzle_slot = UserInterface.original_puzzle_slot

	print("[DEBUG-SNAP] Snapping item back to original slot: ", original_index, " (hotbar: ", is_from_hotbar, ", puzzle: ", original_puzzle_slot != null, ")")

	# Handle puzzle slot case
	if original_puzzle_slot and is_instance_valid(original_puzzle_slot):
		print("[DEBUG-SNAP] Returning item to original puzzle slot")
		original_puzzle_slot.receive_item(item)
		cleanup_after_drop()
		return

	# Find the original slot
	var original_slot = null
	if is_from_hotbar:
		# Find hotbar slot
		var hotbar_slots = get_tree().get_nodes_in_group("HotbarSlot")
		for slot in hotbar_slots:
			if slot.slot_index == original_index:
				original_slot = slot
				break
	else:
		# Find inventory slot
		var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")
		for slot in inventory_slots:
			if slot.slot_index == original_index and not slot.is_hotbar_slot:
				original_slot = slot
				break

	if original_slot:
		# Check if original slot is now occupied
		if original_slot.item:
			print("[DEBUG-SNAP] Original slot occupied, trying to find empty slot instead")
			# Try to find any empty slot as fallback
			if not try_place_in_any_empty_slot(item):
				print("[DEBUG-SNAP] No empty slots available, keeping item on cursor")
				return
		else:
			# Original slot is empty, put item back
			original_slot.putIntoSlot(item)
			if is_from_hotbar:
				PlayerInventory.hotbar[original_index] = [item.item_name, item.item_quantity]
			else:
				PlayerInventory.inventory[original_index] = [item.item_name, item.item_quantity]
			print("[DEBUG-SNAP] Successfully snapped item back to original slot")
	else:
		print("[DEBUG-SNAP] Original slot not found, trying to find empty slot")
		# Original slot not found, try to place in any empty slot
		if not try_place_in_any_empty_slot(item):
			print("[DEBUG-SNAP] No empty slots available, keeping item on cursor")
			return

	cleanup_after_drop()

func try_place_in_any_empty_slot(item: Control) -> bool:
	# Try inventory slots first
	var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")
	for slot in inventory_slots:
		if not slot.is_hotbar_slot and not slot.item:
			slot.putIntoSlot(item)
			PlayerInventory.inventory[slot.slot_index] = [item.item_name, item.item_quantity]
			print("[DEBUG-SNAP] Placed item in empty inventory slot: ", slot.slot_index)
			return true

	# Try hotbar slots if inventory is full
	var hotbar_slots = get_tree().get_nodes_in_group("HotbarSlot")
	for slot in hotbar_slots:
		if not slot.item:
			slot.putIntoSlot(item)
			PlayerInventory.hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
			print("[DEBUG-SNAP] Placed item in empty hotbar slot: ", slot.slot_index)
			return true

	return false

func cleanup_after_drop():
	UserInterface.holding_item = null
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false
	UserInterface.original_puzzle_slot = null
	#if not is_updating:
		#initialize_inventory()

func drop_item_to_world(item):
	if item and is_instance_valid(item):
		var dropped_item = load("res://The_Alchemist_Quest/scences/player/dropped_item.tscn").instantiate()
		var player = get_tree().get_first_node_in_group("player")
		if player:
			dropped_item.global_position = player.global_position
			get_tree().current_scene.add_child(dropped_item)
			dropped_item.initialize(item.item_name, item.item_quantity)
		item.queue_free()

func show_item_description(slot: SlotClass):
	if slot.item:
		item_name_label.text = slot.item.item_name
		popup_label.text = JsonData.get_item_description(slot.item.item_name)
		var image_path = "res://The_Alchemist_Quest/assets/gameDemo/%s.png" % slot.item.item_name.replace(" ", "_")
		item_image_rect.texture = load(image_path) if ResourceLoader.exists(image_path) else null

func show_description_popup(description: String, position: Vector2, item_name: String = "Item"):
	item_name_label.text = item_name
	popup_label.text = description
	popup_panel.global_position = position + Vector2(20, 20)
	popup_panel.show()

func _input(event):
	if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()

	if event is InputEventMouseButton and event.pressed and popup_panel.visible:
		if not popup_panel.get_global_rect().has_point(event.global_position):
			popup_panel.hide()

# Inventory slot interaction functions
func left_click_empty_slot(slot: SlotClass):
	slot.putIntoSlot(UserInterface.holding_item)
	PlayerInventory.add_item_to_empty_slot(UserInterface.holding_item, slot)
	UserInterface.holding_item = null

func left_click_same_item(slot: SlotClass):
	# Truy cập đúng cấu trúc JsonData.item_data["item"][item_name]
	var item_definitions = JsonData.item_data.get("item", {})
	var stack_size = int(item_definitions.get(slot.item.item_name, {"StackSize": 1}).get("StackSize", 1))
	var able_to_add = stack_size - slot.item.item_quantity
	
	if able_to_add >= UserInterface.holding_item.item_quantity:
		PlayerInventory.add_item_quantity(slot, UserInterface.holding_item.item_quantity)
		slot.item.add_item_quantity(UserInterface.holding_item.item_quantity)
		UserInterface.holding_item.queue_free()
	else:
		PlayerInventory.add_item_quantity(slot, able_to_add)
		slot.item.add_item_quantity(able_to_add)
		UserInterface.holding_item.decrease_item_quantity(able_to_add)
	
	UserInterface.holding_item = null if UserInterface.holding_item.item_quantity <= 0 else UserInterface.holding_item

func left_click_different_item(event: InputEvent, slot: SlotClass):
	# SWAP LOGIC: Hoán đổi 2 items khác nhau
	# 1. Lấy item ở slot đích ra và tạm giữ
	var temp_item = slot.pickFromSlot()

	# 2. Đặt item đang giữ trên chuột vào slot đích
	slot.putIntoSlot(UserInterface.holding_item)

	# Cập nhật inventory data cho slot đích
	var slot_index = slot.slot_index
	PlayerInventory.inventory[slot_index] = [UserInterface.holding_item.item_name, UserInterface.holding_item.item_quantity]

	# 3. Đặt temp_item vào slot ban đầu (nơi item đang cầm được lấy ra)
	var original_index = UserInterface.original_slot_index
	var is_from_hotbar = UserInterface.original_is_hotbar

	if is_from_hotbar:
		# Đặt vào hotbar slot
		var hotbar_slots = get_tree().get_nodes_in_group("hotbar_slot")
		for hotbar_slot in hotbar_slots:
			if hotbar_slot.slot_index == original_index:
				hotbar_slot.putIntoSlot(temp_item)
				PlayerInventory.hotbar[original_index] = [temp_item.item_name, temp_item.item_quantity]
				break
	else:
		# Đặt vào inventory slot
		var inventory_slots = inventory_slots.get_children()
		if original_index >= 0 and original_index < inventory_slots.size():
			var original_slot = inventory_slots[original_index]
			original_slot.putIntoSlot(temp_item)
			PlayerInventory.inventory[original_index] = [temp_item.item_name, temp_item.item_quantity]

	# 4. Clear holding item - swap hoàn tất
	UserInterface.holding_item = null

	# 5. Cleanup trạng thái drag
	cleanup_after_drop()
		
#func clear_ui_inventory():
	#print("[UI Inventory] Xóa các item slots")
	#var slots = inventory_slots.get_children()
	#for slot in slots:
		#if slot.item:
			#slot.item.queue_free()
			#slot.item = null
		#slot.initialize_item("",0);
	#print("[UI Inventory] Visual slots đã được clear")
