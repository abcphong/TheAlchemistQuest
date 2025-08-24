extends Panel
class_name PuzzleSlot

@export var expected_item: Array[String] = []
var is_filled := false
var current_item: Control = null  # Item hiện đang nằm trong slot

func _ready():
	add_to_group("PuzzleSlot")

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		print("🖱️ [PUZZLE_INPUT] Mouse event in puzzle slot:")
		print("  - Button: ", event.button_index)
		print("  - Pressed: ", event.pressed)
		print("  - Position: ", event.global_position)
		print("  - Current item: ", current_item.item_name if current_item else "null")
		print("  - UserInterface.holding_item: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
		
		var held_item = UserInterface.holding_item

		# Xử lý cả chuột TRÁI và PHẢI
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			# Mouse button pressed (start of potential drag or click)
			if event.pressed:
				print("  - Mouse pressed detected")
				# TH1: đang cầm item → đặt vào hoặc swap
				if held_item:
					print("  - Case 1: Has held item, will place/swap")
					if is_filled:
						print("  - Slot filled → calling swap_items")
						# Swap items: existing item becomes dragged, new item takes its place
						swap_items(held_item)
					else:
						print("  - Slot empty → calling receive_item")
						# Normal placement in empty slot
						receive_item(held_item)
						UserInterface.holding_item = null
				# TH2: không cầm gì, và slot đã có item
				elif not held_item and current_item:
					print("  - Case 2: No held item, slot has item")
					# Chuột trái: bắt đầu drag (click and hold)
					if event.button_index == MOUSE_BUTTON_LEFT:
						print("  - Left click → calling start_drag_item")
						start_drag_item()
					# Chuột phải: trả về inventory ngay lập tức
					else:
						print("  - Right click → return to inventory")
						var item_to_return = current_item
						current_item = null
						is_filled = false
						$ItemIcon.texture = null
						return_item_to_inventory(item_to_return)

						if get_parent().has_method("check_all_slots_filled"):
							get_parent().check_all_slots_filled()

			# Mouse button released (end drag if dragging)
			else:
				print("  - Mouse released detected")
				# Chỉ xử lý left mouse release khi đang drag
				if event.button_index == MOUSE_BUTTON_LEFT and UserInterface.is_dragging and UserInterface.holding_item:
					print("  - Left release during drag → calling end_drag_item")
					end_drag_item(event.global_position)
		
		print("🖱️ [PUZZLE_INPUT] Event handled")

func receive_item(item: Control):
	print("📥 [PUZZLE_RECEIVE] receive_item called:")
	print("  - Incoming item: ", item.item_name if item else "null", " x", item.item_quantity if item else 0)
	print("  - Current slot filled: ", is_filled)
	print("  - Current item: ", current_item.item_name if current_item else "null")
	
	# Nếu slot đã có item → thực hiện swap thay vì simple return
	if is_filled and current_item:
		print("  - Slot có item → gọi swap_items")
		# Store incoming item temporarily
		var incoming_item = item
		# Call swap logic to handle proper item placement
		swap_items(incoming_item)
		return  # Exit early since swap_items handles everything
	
	print("  - Slot empty → đặt item vào")
	# Đặt item mới vào slot
	current_item = item
	
	var tex_node = item.get_node_or_null("TextureRect")
	if tex_node:
		$ItemIcon.texture = tex_node.texture
		print("  - Set ItemIcon texture")
	else:
		print("  - WARNING: No TextureRect found")
	
	add_child(item)
	item.visible = false
	item.position = Vector2.ZERO
	is_filled = true
	UserInterface.is_dragging = false
	
	print("  - Item added to slot successfully")
	print("  - is_filled = ", is_filled)
	print("  - UserInterface.is_dragging = ", UserInterface.is_dragging)
	
	if get_parent().has_method("check_all_slots_filled"):
		print("  - Calling check_all_slots_filled")
		get_parent().check_all_slots_filled()
	
	print("✅ [PUZZLE_RECEIVE] receive_item completed")

func start_drag_item():
	print("🚀 [PUZZLE_DRAG] start_drag_item called:")
	print("  - Current item: ", current_item.item_name if current_item else "null")
	
	if not current_item:
		print("❌ [PUZZLE_DRAG] No current item, returning")
		return

	print("  - Making item visible and setting to holding_item")
	# Hiện lại item để drag
	current_item.visible = true
	UserInterface.holding_item = current_item

	# Set original slot info để biết item đến từ puzzle slot
	UserInterface.original_slot_index = -1  # -1 indicates puzzle slot
	UserInterface.original_is_hotbar = false
	UserInterface.original_puzzle_slot = self  # Store reference to this puzzle slot

	print("  - Set UserInterface.original_slot_index = ", UserInterface.original_slot_index)
	print("  - Set UserInterface.original_puzzle_slot = ", self.name)

	# Clear slot
	current_item = null
	is_filled = false
	$ItemIcon.texture = null

	print("  - Cleared puzzle slot")

	# Add item to DraggingLayer với z-index cao
	var dragging_layer = get_tree().get_current_scene().get_node_or_null("DraggingLayer")
	if dragging_layer:
		print("  - Adding to DraggingLayer")
		dragging_layer.add_child(UserInterface.holding_item)
	else:
		print("  - DraggingLayer not found, using fallback")
		# Fallback to UserInterface if DraggingLayer not found
		var ui = get_tree().get_first_node_in_group("UserInterface")
		if ui:
			ui.add_child(UserInterface.holding_item)
		else:
			get_tree().get_root().add_child(UserInterface.holding_item)

	# Set drag properties
	UserInterface.holding_item.global_position = get_global_mouse_position()
	UserInterface.holding_item.set_z_as_relative(false)
	UserInterface.holding_item.z_index = 9999
	UserInterface.is_dragging = true

	print("  - Set UserInterface.is_dragging = ", UserInterface.is_dragging)
	print("  - Item position: ", UserInterface.holding_item.global_position)

	# Update puzzle state
	if get_parent().has_method("check_all_slots_filled"):
		print("  - Calling check_all_slots_filled")
		get_parent().check_all_slots_filled()
	
	print("✅ [PUZZLE_DRAG] start_drag_item completed")

func swap_items(incoming_item: Control):
	if not current_item or not incoming_item:
		print("❌ [PUZZLE_SWAP] Không thể swap - thiếu item")
		return

	print("🔄 [PUZZLE_SWAP] Bắt đầu swap:")
	print("  - Incoming item: ", incoming_item.item_name, " x", incoming_item.item_quantity)
	print("  - Existing item: ", current_item.item_name, " x", current_item.item_quantity)
	print("  - Original slot index: ", UserInterface.original_slot_index)
	print("  - Original is hotbar: ", UserInterface.original_is_hotbar)

	# Store reference to existing item
	var existing_item = current_item

	# Clear current slot
	current_item = null
	is_filled = false
	$ItemIcon.texture = null

	# Remove existing item from this slot's children
	if existing_item.get_parent() == self:
		remove_child(existing_item)

	# Place incoming item in slot
	current_item = incoming_item

	var tex_node = incoming_item.get_node_or_null("TextureRect")
	if tex_node:
		$ItemIcon.texture = tex_node.texture

	add_child(incoming_item)
	incoming_item.visible = false
	incoming_item.position = Vector2.ZERO
	is_filled = true

	print("✅ [PUZZLE_SWAP] Đã đặt incoming item vào puzzle slot")

	# Determine where to place the displaced item based on source
	var source_puzzle_slot = UserInterface.original_puzzle_slot
	var original_slot_index = UserInterface.original_slot_index
	var original_is_hotbar = UserInterface.original_is_hotbar

	# Case 1: Incoming item from another puzzle slot (bidirectional puzzle swap)
	if source_puzzle_slot and is_instance_valid(source_puzzle_slot) and source_puzzle_slot != self:
		print("🔄 [PUZZLE_SWAP] Case 1: Puzzle to puzzle swap")
		if not source_puzzle_slot.is_filled:
			source_puzzle_slot.receive_item(existing_item)
		else:
			# Source puzzle slot occupied, fallback to inventory
			return_item_to_inventory(existing_item)
	
	# Case 2: Incoming item from inventory (inventory-to-puzzle swap)
	elif original_slot_index >= 0:
		print("🔄 [PUZZLE_SWAP] Case 2: Inventory to puzzle swap")
		print("  - Returning existing item to slot: ", original_slot_index, " (hotbar: ", original_is_hotbar, ")")
		return_item_to_inventory_slot(existing_item, original_slot_index, original_is_hotbar)
	
	# Case 3: Fallback - return to general inventory
	else:
		print("🔄 [PUZZLE_SWAP] Case 3: Fallback to general inventory")
		return_item_to_inventory(existing_item)

	# Clear any dragging state since we're not dragging the displaced item
	UserInterface.holding_item = null
	UserInterface.is_dragging = false

	# Update puzzle state
	if get_parent().has_method("check_all_slots_filled"):
		get_parent().check_all_slots_filled()
	
	# Defer UI refresh until after all operations complete to prevent conflicts
	call_deferred("deferred_ui_refresh")
	
	print("✅ [PUZZLE_SWAP] Swap hoàn tất")

func end_drag_item(mouse_pos: Vector2):
	print("🏁 [PUZZLE_END_DRAG] end_drag_item called:")
	print("  - Mouse position: ", mouse_pos)
	print("  - UserInterface.holding_item: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
	print("  - UserInterface.is_dragging: ", UserInterface.is_dragging)
	
	if not UserInterface.holding_item or not UserInterface.is_dragging:
		print("❌ [PUZZLE_END_DRAG] No holding item or not dragging, returning")
		return

	# Tìm slot hoặc inventory để drop item
	var dropped_successfully = false

	# Kiểm tra xem có drop vào puzzle slot khác không
	var puzzle_slots = []
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlotTrial")
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlot")

	print("  - Found ", puzzle_slots.size(), " puzzle slots to check")

	for puzzle_slot in puzzle_slots:
		if puzzle_slot != self and puzzle_slot is Control:
			var slot_rect = Rect2(puzzle_slot.global_position, puzzle_slot.size)
			print("    - Checking puzzle slot: ", puzzle_slot.name, " rect: ", slot_rect)
			if slot_rect.has_point(mouse_pos):
				print("    ✅ Mouse over puzzle slot: ", puzzle_slot.name)
				# Check if slot is filled - if so, swap items
				if puzzle_slot.is_filled and puzzle_slot.has_method("swap_items"):
					print("    - Swapping with filled puzzle slot")
					puzzle_slot.swap_items(UserInterface.holding_item)
					# Note: swap_items handles UserInterface.holding_item and is_dragging internally
					dropped_successfully = true
					break
				# If slot is empty, use normal receive_item
				elif not puzzle_slot.is_filled and puzzle_slot.has_method("receive_item"):
					print("    - Placing in empty puzzle slot")
					puzzle_slot.receive_item(UserInterface.holding_item)
					UserInterface.holding_item = null
					UserInterface.is_dragging = false
					dropped_successfully = true
					break
				# For PuzzleSlotTrial, try process_drop method
				elif puzzle_slot.has_method("process_drop"):
					print("    - Using process_drop method")
					if puzzle_slot.is_filled and puzzle_slot.has_method("swap_items"):
						puzzle_slot.swap_items(UserInterface.holding_item)
						dropped_successfully = true
						break
					elif not puzzle_slot.is_filled:
						puzzle_slot.process_drop(UserInterface.holding_item, mouse_pos)
						UserInterface.holding_item = null
						UserInterface.is_dragging = false
						dropped_successfully = true
						break

	# Nếu không drop vào puzzle slot, thử drop vào inventory
	if not dropped_successfully:
		print("  - No puzzle slot found, trying inventory system")
		# Try different group names
		var inventory_system = get_tree().get_first_node_in_group("InventorySystem")
		if not inventory_system:
			print("  - No 'InventorySystem' group, trying 'Inventory'")
			inventory_system = get_tree().get_first_node_in_group("Inventory")
		
		if inventory_system and inventory_system.has_method("try_drop_item"):
			print("  - Found inventory system: ", inventory_system.name)
			print("  - Calling inventory_system.try_drop_item with mouse_pos: ", mouse_pos)
			print("  - UserInterface.holding_item before call: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
			inventory_system.try_drop_item(null, mouse_pos)
			print("  - UserInterface.holding_item after call: ", UserInterface.holding_item.item_name if UserInterface.holding_item else "null")
			print("  - Inventory system call completed")
			dropped_successfully = true
		else:
			print("  - No inventory system found or no try_drop_item method")
			if inventory_system:
				print("  - Found inventory_system: ", inventory_system.name, " but no try_drop_item method")
			else:
				print("  - No inventory_system found in any group")

	# Nếu vẫn không drop được, trả về inventory
	if not dropped_successfully and UserInterface.holding_item:
		print("  - Still not dropped, returning to inventory")
		return_item_to_inventory(UserInterface.holding_item)
		UserInterface.holding_item = null
		UserInterface.is_dragging = false
	
	print("✅ [PUZZLE_END_DRAG] end_drag_item completed")

func return_item_to_inventory(item: Control):
	print("📤 [PUZZLE_RETURN] return_item_to_inventory called:")
	print("  - Item: ", item.item_name if item else "null")
	print("  - Original slot index: ", UserInterface.original_slot_index)
	
	# Try to return to specific slot if we have the info
	if UserInterface.original_slot_index >= 0:
		print("  - Trying to return to specific slot: ", UserInterface.original_slot_index)
		# Store original values before clearing to prevent recursion
		var temp_slot_index = UserInterface.original_slot_index
		var temp_is_hotbar = UserInterface.original_is_hotbar
		
		# Clear original info BEFORE calling return_item_to_inventory_slot to prevent infinite recursion
		UserInterface.original_slot_index = -1
		UserInterface.original_is_hotbar = false
		UserInterface.original_puzzle_slot = null
		
		return_item_to_inventory_slot(item, temp_slot_index, temp_is_hotbar)
		return
	
	print("  - No specific slot, using general inventory")
	if item.get_parent():
		item.get_parent().remove_child(item)

	var success := UserInterface.return_item_to_inventory(item)
	if not success:
		print("  - Failed to add to inventory, dropping to world")
		get_tree().get_root().add_child(item)
		item.visible = true
		item.global_position = get_global_mouse_position()
	else:
		print("  ✅ Successfully returned to general inventory")

func return_item_to_inventory_slot(item: Control, slot_index: int, is_hotbar: bool):
	"""Return item to specific inventory slot to maintain proper swap behavior"""
	if not item or not is_instance_valid(item):
		print("❌ [RETURN_TO_SLOT] Item không hợp lệ")
		return

	print("📥 [RETURN_TO_SLOT] Đang trả item về slot:")
	print("  - Item: ", item.item_name, " x", item.item_quantity)
	print("  - Target slot index: ", slot_index)
	print("  - Is hotbar: ", is_hotbar)

	# Remove from current parent
	if item.get_parent():
		item.get_parent().remove_child(item)

	# Find target slot
	var target_slot = null
	
	if is_hotbar:
		# Find hotbar slot
		var hotbar_slots = get_tree().get_nodes_in_group("HotbarSlot")
		print("  - Tìm trong ", hotbar_slots.size(), " hotbar slots")
		for slot in hotbar_slots:
			if slot.slot_index == slot_index:
				target_slot = slot
				print("  - Tìm thấy hotbar slot ", slot_index)
				break
	else:
		# Find inventory slot
		var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")
		print("  - Tìm trong ", inventory_slots.size(), " inventory slots")
		for slot in inventory_slots:
			if slot.slot_index == slot_index and not slot.is_hotbar_slot:
				target_slot = slot
				print("  - Tìm thấy inventory slot ", slot_index)
				break

	if target_slot:
		# Debug target slot state
		print("  - Target slot state:")
		print("    * target_slot.item: ", target_slot.item.item_name if target_slot.item else "null")
		print("    * target_slot.slot_index: ", target_slot.slot_index)
		
		# Check PlayerInventory data for comparison
		if is_hotbar:
			print("    * PlayerInventory.hotbar[", slot_index, "]: ", PlayerInventory.hotbar[slot_index])
		else:
			print("    * PlayerInventory.inventory[", slot_index, "]: ", PlayerInventory.inventory[slot_index])
		
		# Check if target slot is empty
		if not target_slot.item:
			print("✅ [RETURN_TO_SLOT] Target slot empty, đặt item vào")
			
			# Place item directly in the original slot
			target_slot.putIntoSlot(item)
			
			# Debug: check PlayerInventory data after placing
			if is_hotbar:
				print("  - PlayerInventory.hotbar[", slot_index, "] AFTER: ", PlayerInventory.hotbar[slot_index])
			else:
				print("  - PlayerInventory.inventory[", slot_index, "] AFTER: ", PlayerInventory.inventory[slot_index])
			
			# Skip immediate UI refresh to prevent conflicts during swap
			print("✅ [RETURN_TO_SLOT] Hoàn tất đặt item vào slot gốc")
		else:
			print("⚠️ [RETURN_TO_SLOT] Target slot đã có item:", target_slot.item.item_name)
			print("  - Item type: ", target_slot.item.get_class())
			print("  - Item valid: ", is_instance_valid(target_slot.item))
			# Original slot is occupied, clear original info to prevent infinite recursion
			print("  - Clearing original slot info to prevent recursion")
			UserInterface.original_slot_index = -1
			UserInterface.original_is_hotbar = false
			UserInterface.original_puzzle_slot = null
			return_item_to_inventory(item)
	else:
		print("❌ [RETURN_TO_SLOT] Không tìm thấy target slot")
		# Slot not found, clear original info to prevent infinite recursion
		print("  - Clearing original slot info to prevent recursion")  
		UserInterface.original_slot_index = -1
		UserInterface.original_is_hotbar = false
		UserInterface.original_puzzle_slot = null
		return_item_to_inventory(item)

func force_refresh_inventory_ui():
	"""Force refresh inventory UI to show updated items"""
	print("🔄 [UI_REFRESH] Bắt đầu refresh inventory UI")
	
	# Skip refresh during active swap operations to prevent visual conflicts
	if UserInterface.is_dragging:
		print("  - Skipping UI refresh - drag operation in progress")
		return
	
	# Clear any lingering drag state
	UserInterface.is_dragging = false
	UserInterface.holding_item = null
	
	# Try UserInterface.update_all_ui()
	var ui = get_tree().get_first_node_in_group("UserInterface")
	if ui and ui.has_method("update_all_ui"):
		print("  - Gọi UserInterface.update_all_ui()")
		ui.call_deferred("update_all_ui")
	
	# Try InventorySystem.initialize_inventory()
	var inventory_system = get_tree().get_first_node_in_group("InventorySystem")
	if inventory_system and inventory_system.has_method("initialize_inventory"):
		print("  - Gọi InventorySystem.initialize_inventory()")
		inventory_system.call_deferred("initialize_inventory")
	
	# Force emit inventory_changed signal  
	if PlayerInventory.has_signal("inventory_changed"):
		print("  - Emit PlayerInventory.inventory_changed signal")
		PlayerInventory.inventory_changed.emit()
	
	print("✅ [UI_REFRESH] Hoàn tất refresh inventory UI")

func deferred_ui_refresh():
	"""Deferred UI refresh to ensure all swap operations complete first"""
	print("🔄 [DEFERRED_REFRESH] Starting deferred UI refresh")
	force_refresh_inventory_ui()
