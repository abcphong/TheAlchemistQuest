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
	# Add to group for puzzle slot detection
	add_to_group("InventorySystem")
	add_to_group("Inventory")
	
	if not is_initialized:
		initialize_inventory_system()
		connect_signals()
		#Thêm connection vào
		# PlayerInventory.connect("inventory_changed",Callable(self,"clear_ui_inventory"))
		PlayerInventory.connect("inventory_changed", Callable(self, "safe_initialize_inventory"))

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
	# DISABLED: This was causing visual corruption after swap operations
	# PlayerInventory.inventory_changed.connect(safe_initialize_inventory)

func _on_inventory_updated():
	# DISABLED: This was causing visual corruption after swap operations
	# Swap operations handle their own visual updates via putIntoSlot()
	# if not is_updating:
	#	safe_initialize_inventory()
	pass

# SAFE wrapper for initialize_inventory that checks for ongoing operations
func safe_initialize_inventory():
	if is_drag_operation_active():
		# Defer initialization until drag operation completes
		call_deferred("_check_and_initialize")
	else:
		initialize_inventory()

func _check_and_initialize():
	# Double-check that drag operation has completed
	if not is_drag_operation_active():
		initialize_inventory()
	else:
		# Still dragging, try again later
		call_deferred("_check_and_initialize")



func initialize_inventory():
	if is_updating:
		return

	# SAFETY CHECK: Prevent destructive operations during ongoing drag operations
	if is_drag_operation_active():
		return

	is_updating = true
	var slots = inventory_slots.get_children()

	# SAFE CLEARING: Only clear items that are not currently being dragged
	for slot in slots:
		if slot.item and not is_item_being_dragged(slot.item):
			slot.item.queue_free()
			slot.item = null
		elif slot.item and is_item_being_dragged(slot.item):
			pass  # Preserve dragged item

	# Reinitialize slots with current inventory data
	for i in range(slots.size()):
		var slot = slots[i]
		slot.slot_index = i
		slot.is_hotbar_slot = false

		# Truyền inventory gốc cho từng slot
		slot.set_inventory_reference(PlayerInventory.inventory)

		# Skip initialization if slot already has the dragged item
		if slot.item and is_item_being_dragged(slot.item):
			continue

		if PlayerInventory.inventory.has(i) and PlayerInventory.inventory[i] != null:
			var item_name = str(PlayerInventory.inventory[i][0])
			var item_quantity = int(PlayerInventory.inventory[i][1])
			slot.initialize_item(item_name, item_quantity)
		else:
			slot.initialize_item("", 0)

	is_updating = false
	emit_signal("inventory_updated")

# SAFETY FUNCTIONS: Detect ongoing drag operations
func is_drag_operation_active() -> bool:
	# Check if any drag operation is currently active
	return (UserInterface.holding_item != null and is_instance_valid(UserInterface.holding_item)) or \
		   UserInterface.is_dragging or \
		   is_dragging or \
		   UserInterface.is_right_click_holding

func is_item_being_dragged(item: Control) -> bool:
	# Check if specific item is currently being dragged
	if not item or not is_instance_valid(item):
		return false

	return UserInterface.holding_item == item

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
		print("🎯 [INVENTORY_DRAG] Bắt đầu drag từ inventory:")
		print("  - Item: ", slot.item.item_name, " x", slot.item.item_quantity)
		print("  - Slot index: ", slot.slot_index)
		print("  - Is hotbar slot: ", slot.is_hotbar_slot)
		print("  - Slot has visual item before pick: ", slot.item != null)
		
		UserInterface.holding_item = slot.pickFromSlot()
		UserInterface.original_slot_index = slot.slot_index
		UserInterface.original_is_hotbar = slot.is_hotbar_slot
		UserInterface.original_puzzle_slot = null  # Clear puzzle slot reference
		
		print("  - Slot has visual item after pick: ", slot.item != null)
		print("  - Set UserInterface.original_slot_index =", UserInterface.original_slot_index)
		print("  - Set UserInterface.original_is_hotbar =", UserInterface.original_is_hotbar)
		
		if dragging_layer:
			dragging_layer.add_child(UserInterface.holding_item)
		else:
			UserInterface.add_child(UserInterface.holding_item)
		
		UserInterface.holding_item.z_index = 9999
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
		is_dragging = true
		UserInterface.is_dragging = true
		
		print("✅ [INVENTORY_DRAG] Drag started successfully")

func end_drag_item(mouse_pos: Vector2):
	if UserInterface.holding_item:
		is_dragging = false
		UserInterface.is_dragging = false
		var hovered_slot = get_slot_under_mouse()
		try_drop_item(hovered_slot, mouse_pos)

func get_slot_under_mouse() -> SlotClass:
	# Always check inventory slots, regardless of puzzle UI state
	# Puzzle slot priority is handled in try_drop_item() instead
	var mouse_pos = get_viewport().get_mouse_position()
	print("🔍 [GET_SLOT] get_slot_under_mouse called:")
	print("  - Mouse position: ", mouse_pos)
	
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			print("  - Found slot under mouse: ", slot.slot_index, " item: ", slot.item.item_name if slot.item else "empty")
			return slot
		else:
			# Debug slot positions
			if slot.slot_index < 5:  # Only log first few slots to avoid spam
				print("  - Checked slot ", slot.slot_index, " at ", slot.global_position, " size ", slot.size, " - not under mouse")
	
	print("  - No slot found under mouse")
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
	print("🎯 [TRY_DROP] Bắt đầu try_drop_item:")
	print("  - Mouse position: ", mouse_pos)
	print("  - Holding item: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
	print("  - Slot parameter: ", slot)

	# PRIORITY 1: Check puzzle slots first (if any exist)
	var puzzle_slots = []
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlotTrial")
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlot")

	print("  - Found ", puzzle_slots.size(), " puzzle slots")
	
	# Puzzle slot handling - HIGHEST PRIORITY
	for puzzle_slot in puzzle_slots:
		print("  - Checking puzzle slot: ", puzzle_slot.name)
		print("    * Type: ", puzzle_slot.get_class())
		print("    * Is Control: ", puzzle_slot is Control)
		print("    * Is CanvasLayer: ", puzzle_slot is CanvasLayer)
		
		# Skip if not a Control (CanvasLayer doesn't have global_position)
		if not puzzle_slot is Control:
			print("    * Skipping - not a Control")
			continue
			
		print("    * Global position: ", puzzle_slot.global_position)
		print("    * Size: ", puzzle_slot.size)
		
		var slot_rect = Rect2(puzzle_slot.global_position, puzzle_slot.size)
		print("    * Slot rect: ", slot_rect)
		print("    * Mouse in rect: ", slot_rect.has_point(mouse_pos))
		
		if slot_rect.has_point(mouse_pos):
			print("✅ [TRY_DROP] Mouse over puzzle slot: ", puzzle_slot.name)
			print("    * Has process_drop: ", puzzle_slot.has_method("process_drop"))
			print("    * Is filled: ", puzzle_slot.is_filled)
			print("    * Has swap_items: ", puzzle_slot.has_method("swap_items"))
			
			if puzzle_slot.has_method("process_drop"):
				print("  - Using process_drop method")
				handle_puzzle_drop(puzzle_slot)
			else:
				# Check if puzzle slot is already filled - if so, use swap logic
				if puzzle_slot.is_filled and puzzle_slot.has_method("swap_items"):
					print("  - Using swap_items method")
					puzzle_slot.swap_items(UserInterface.holding_item)
				else:
					print("  - Using receive_item method")
					puzzle_slot.receive_item(UserInterface.holding_item)
					print("  - Clearing UserInterface.holding_item")
					UserInterface.holding_item = null
					UserInterface.is_dragging = false
			print("  - Calling cleanup_after_drop()")
			cleanup_after_drop()
			return

	print("⚠️ [TRY_DROP] Không tìm thấy puzzle slot phù hợp")
	
	# PRIORITY 2: Inventory slot handling - CONSISTENT LOGIC
	# Use the slot parameter passed from get_slot_under_mouse() for consistency
	if slot is SlotClass:
		print("📦 [TRY_DROP] Dropping vào inventory slot: ", slot.slot_index)
		handle_inventory_drop(slot)
		# Ensure consistent cleanup after inventory operations
		cleanup_after_drop()
		return
	
	# PRIORITY 2.5: If no slot parameter, manually check inventory slots at mouse position
	if not slot:
		print("📍 [TRY_DROP] No slot parameter, checking inventory slots manually")
		for inv_slot in get_tree().get_nodes_in_group("InventorySlot"):
			if not inv_slot.is_hotbar_slot and inv_slot.slot_index >= 0:  # Only check main inventory slots
				var slot_rect = Rect2(inv_slot.global_position, inv_slot.size)
				print("    - Checking inventory slot ", inv_slot.slot_index, " at ", inv_slot.global_position, " size ", inv_slot.size)
				print("    - Slot rect: ", slot_rect, " mouse in rect: ", slot_rect.has_point(mouse_pos))
				if slot_rect.has_point(mouse_pos):
					print("✅ [TRY_DROP] Found inventory slot under mouse: ", inv_slot.slot_index)
					print("    - Slot has item: ", inv_slot.item.item_name if inv_slot.item else "empty")
					handle_inventory_drop(inv_slot)
					cleanup_after_drop()
					return

	print("📍 [TRY_DROP] Fallback - tìm nearest empty slot")
	# PRIORITY 3: Fallback - nearest empty slot
	place_item_in_nearest_slot(mouse_pos)
	# Ensure cleanup after fallback placement
	cleanup_after_drop()


func handle_puzzle_drop(puzzle_slot: Node):
	var held_item = UserInterface.holding_item
	if held_item and puzzle_slot.has_method("process_drop"):
		puzzle_slot.process_drop(held_item, get_viewport().get_mouse_position())
		is_puzzle_interaction = true
		held_item.queue_free()
		is_puzzle_interaction = false

func handle_inventory_drop(slot: SlotClass):
	# Null safety checks
	if not slot or not UserInterface.holding_item:
		return

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

	# Handle puzzle slot case
	if original_puzzle_slot and is_instance_valid(original_puzzle_slot):
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
			# Try to find any empty slot as fallback
			if not try_place_in_any_empty_slot(item):
				return
		else:
			# Original slot is empty, put item back
			original_slot.putIntoSlot(item)
			if is_from_hotbar:
				PlayerInventory.hotbar[original_index] = [item.item_name, item.item_quantity]
			else:
				PlayerInventory.inventory[original_index] = [item.item_name, item.item_quantity]
	else:
		# Original slot not found, try to place in any empty slot
		if not try_place_in_any_empty_slot(item):
			return

	cleanup_after_drop()

func try_place_in_any_empty_slot(item: Control) -> bool:
	# Try inventory slots first
	var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")
	for slot in inventory_slots:
		if not slot.is_hotbar_slot and not slot.item:
			slot.putIntoSlot(item)
			PlayerInventory.inventory[slot.slot_index] = [item.item_name, item.item_quantity]
			return true

	# Try hotbar slots if inventory is full
	var hotbar_slots = get_tree().get_nodes_in_group("HotbarSlot")
	for slot in hotbar_slots:
		if not slot.item:
			slot.putIntoSlot(item)
			PlayerInventory.hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
			return true

	return false

func place_item_in_nearest_slot(mouse_pos: Vector2):
	if not UserInterface.holding_item or not is_instance_valid(UserInterface.holding_item):
		cleanup_after_drop()
		return

	var held_item = UserInterface.holding_item

	# Try to find nearest empty slot
	var nearest_slot = find_nearest_empty_slot(mouse_pos)

	if nearest_slot and nearest_slot.slot_index >= 0:
		# Place item in nearest empty slot
		nearest_slot.putIntoSlot(held_item)

		# Update inventory data
		if nearest_slot.is_hotbar_slot:
			PlayerInventory.hotbar[nearest_slot.slot_index] = [held_item.item_name, held_item.item_quantity]
		else:
			PlayerInventory.inventory[nearest_slot.slot_index] = [held_item.item_name, held_item.item_quantity]

		UserInterface.holding_item = null
	else:
		# No empty slot found or invalid slot, fallback to original behavior (snap back to original slot)
		snap_item_back_to_original_slot()
		return

	# Note: cleanup_after_drop() is called by the calling function (try_drop_item)

func find_nearest_empty_slot(mouse_position: Vector2):
	var nearest_slot = null
	var nearest_distance = INF

	# Check inventory slots first (exclude hotbar for priority)
	var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")

	for slot in inventory_slots:
		# Check if slot is effectively empty and has valid slot_index
		var is_slot_empty = (not slot.item) or (slot.item and slot.item.item_quantity <= 0) or (slot.item and not slot.item.visible)

		if is_slot_empty and not slot.is_hotbar_slot and is_instance_valid(slot) and slot.slot_index >= 0:
			var slot_center = slot.global_position + slot.size / 2
			var distance = mouse_position.distance_to(slot_center)

			if distance < nearest_distance:
				nearest_distance = distance
				nearest_slot = slot

	# If no inventory slot found, check hotbar slots
	if not nearest_slot:
		var hotbar_slots = get_tree().get_nodes_in_group("HotbarSlot")

		for slot in hotbar_slots:
			var is_slot_empty = (not slot.item) or (slot.item and slot.item.item_quantity <= 0) or (slot.item and not slot.item.visible)

			if is_slot_empty and is_instance_valid(slot) and slot.slot_index >= 0:
				var slot_center = slot.global_position + slot.size / 2
				var distance = mouse_position.distance_to(slot_center)

				if distance < nearest_distance:
					nearest_distance = distance
					nearest_slot = slot

	return nearest_slot

func cleanup_after_drop():
	print("🧹 [CLEANUP] cleanup_after_drop() called:")
	print("  - UserInterface.holding_item before: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
	print("  - UserInterface.is_dragging before: ", UserInterface.is_dragging)
	
	UserInterface.holding_item = null
	UserInterface.is_dragging = false
	is_dragging = false
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false
	UserInterface.original_puzzle_slot = null
	
	print("  - UserInterface.holding_item after: ", UserInterface.holding_item)
	print("  - UserInterface.is_dragging after: ", UserInterface.is_dragging)
	
	# Defer UI refresh after cleanup to ensure visual consistency
	call_deferred("deferred_final_ui_refresh")
	
	print("✅ [CLEANUP] cleanup_after_drop() completed")
	#if not is_updating:
		#initialize_inventory()

func drop_item_to_world(item):
	if item and is_instance_valid(item):
		var dropped_item = load("res://The_Alchemist_Quest/scenes/player/dropped_item.tscn").instantiate()
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
	# Note: putIntoSlot() automatically calls update_inventory_dict() to update PlayerInventory data
	UserInterface.holding_item = null
	# Ensure visual consistency
	emit_signal("inventory_updated")

func left_click_same_item(slot: SlotClass):

	# Null safety checks
	if not slot or not slot.item or not UserInterface.holding_item:
		return

	# Truy cập đúng cấu trúc JsonData.item_data["item"][item_name]
	var item_definitions = JsonData.item_data.get("item", {})
	var stack_size = int(item_definitions.get(slot.item.item_name, {"StackSize": 1}).get("StackSize", 1))
	var able_to_add = stack_size - slot.item.item_quantity

	if able_to_add >= UserInterface.holding_item.item_quantity:
		PlayerInventory.add_item_quantity(slot, UserInterface.holding_item.item_quantity)
		# Additional null check before calling add_item_quantity
		if slot.item and is_instance_valid(slot.item):
			slot.item.add_item_quantity(UserInterface.holding_item.item_quantity)
		else:
			return
		UserInterface.holding_item.queue_free()
	else:
		PlayerInventory.add_item_quantity(slot, able_to_add)
		# Additional null check before calling add_item_quantity
		if slot.item and is_instance_valid(slot.item):
			slot.item.add_item_quantity(able_to_add)
		else:
			return
		UserInterface.holding_item.decrease_item_quantity(able_to_add)

	UserInterface.holding_item = null if UserInterface.holding_item and UserInterface.holding_item.item_quantity <= 0 else UserInterface.holding_item

	# Force UI refresh to ensure visual consistency
	emit_signal("inventory_updated")

	# Note: cleanup_after_drop() is called by the calling function (try_drop_item) for consistency

func left_click_different_item(event: InputEvent, slot: SlotClass):
	# SWAP LOGIC: Hoán đổi 2 items khác nhau
	print("🔄 [LEFT_CLICK_DIFFERENT] Starting inventory swap:")
	print("  - UserInterface.holding_item: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
	print("  - Target slot item: ", slot.item.item_name if slot.item else "null")
	
	# Safety check: If no holding item, probably already handled by puzzle swap
	if not UserInterface.holding_item:
		print("❌ [LEFT_CLICK_DIFFERENT] No holding item - probably handled by puzzle swap already")
		return
	
	# 1. Lấy item ở slot đích ra và tạm giữ
	var temp_item = slot.pickFromSlot()
	print("  - Picked from target slot: ", temp_item.item_name if temp_item else "null")

	# 2. Đặt item đang giữ trên chuột vào slot đích
	slot.putIntoSlot(UserInterface.holding_item)
	print("  - Put holding item into target slot")
	# Note: putIntoSlot() automatically calls update_inventory_dict() to update PlayerInventory data

	# 3. Đặt temp_item vào slot ban đầu (nơi item đang cầm được lấy ra)
	var original_index = UserInterface.original_slot_index
	var is_from_hotbar = UserInterface.original_is_hotbar
	var original_puzzle_slot = UserInterface.original_puzzle_slot

	print("🔄 [INVENTORY_SWAP] Placing displaced item:")
	print("  - Displaced item: ", temp_item.item_name, " x", temp_item.item_quantity)
	print("  - Original index: ", original_index)
	print("  - From hotbar: ", is_from_hotbar)
	print("  - Original puzzle slot: ", original_puzzle_slot.name if original_puzzle_slot else "null")

	# Case 1: From puzzle slot (original_index = -1)
	if original_index == -1 and original_puzzle_slot and is_instance_valid(original_puzzle_slot):
		print("  - Case 1: Returning to puzzle slot")
		if original_puzzle_slot.has_method("receive_item"):
			original_puzzle_slot.receive_item(temp_item)
			print("  ✅ Returned ", temp_item.item_name, " to puzzle slot ", original_puzzle_slot.name)
		else:
			print("  ❌ Puzzle slot has no receive_item method")
	# Case 2: From hotbar slot  
	elif is_from_hotbar:
		print("  - Case 2: Returning to hotbar slot")
		# Đặt vào hotbar slot
		var hotbar_slots = get_tree().get_nodes_in_group("hotbar_slot")
		for hotbar_slot in hotbar_slots:
			if hotbar_slot.slot_index == original_index:
				hotbar_slot.putIntoSlot(temp_item)
				print("  ✅ Returned ", temp_item.item_name, " to hotbar slot ", original_index)
				break
	# Case 3: From inventory slot
	elif original_index >= 0:
		print("  - Case 3: Returning to inventory slot")
		# Đặt vào inventory slot
		var inventory_slot_children = inventory_slots.get_children()
		if original_index < inventory_slot_children.size():
			var original_slot = inventory_slot_children[original_index]
			original_slot.putIntoSlot(temp_item)
			print("  ✅ Returned ", temp_item.item_name, " to inventory slot ", original_index)
	else:
		print("  ❌ Unknown original location, temp_item lost: ", temp_item.item_name)

	# 4. Clear holding item - swap hoàn tất
	UserInterface.holding_item = null
	print("✅ [INVENTORY_SWAP] Swap completed")

	# 5. Force UI refresh to ensure visual consistency
	# This is especially important when puzzle UI is active
	emit_signal("inventory_updated")

	# Note: cleanup_after_drop() is called by the calling function (try_drop_item) for consistency

func deferred_final_ui_refresh():
	"""Final UI refresh after all swap operations complete"""
	print("🔄 [FINAL_REFRESH] Final UI refresh after swap completion")
	
	# Try UserInterface.update_all_ui()
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui and ui.has_method("update_all_ui"):
		print("  - Final call to UserInterface.update_all_ui()")
		ui.update_all_ui()
	
	# Try InventorySystem.initialize_inventory()
	if has_method("initialize_inventory"):
		print("  - Final call to InventorySystem.initialize_inventory()")
		initialize_inventory()
	
	print("✅ [FINAL_REFRESH] Final UI refresh completed")
		
#func clear_ui_inventory():
	#var slots = inventory_slots.get_children()
	#for slot in slots:
		#if slot.item:
			#slot.item.queue_free()
			#slot.item = null
		#slot.initialize_item("",0);
