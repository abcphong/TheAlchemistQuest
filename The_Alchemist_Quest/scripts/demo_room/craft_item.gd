extends Panel
class_name PuzzleSlotTrial

@export var expected_item: String = ""  # Tên item đúng để kiểm tra
var is_filled := false
var current_item: Control = null  # Item hiện đang nằm trong slot

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("PuzzleSlotTrial")
	if not $ItemIcon is TextureRect:
		print("❌ Error: $ItemIcon is not a TextureRect in", name)
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 0
	$ItemIcon.z_index = 10
	$ItemIcon.visible = true
	$ItemIcon.modulate = Color(1, 1, 1, 1)
	$ItemIcon.expand = true
	$ItemIcon.stretch_mode = TextureRect.STRETCH_SCALE
	$ItemIcon.position = Vector2(0, 0)
	$ItemIcon.size = Vector2(52, 52)
	size = Vector2(52, 52)
	clip_contents = false
	


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var held_item = UserInterface.holding_item

		# Xử lý cả chuột TRÁI và PHẢI
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			# Mouse button pressed (start of potential drag or click)
			if event.pressed:
				# TH1: đang cầm item → đặt vào hoặc swap
				if held_item:
					if is_filled:
						# Swap items: existing item becomes dragged, new item takes its place
						swap_items(held_item)
					else:
						# Normal placement in empty slot
						process_drop(held_item, event.global_position)
						UserInterface.holding_item = null
				# TH2: không cầm gì, và slot đã có item
				elif not held_item and current_item:
					# Chuột trái: bắt đầu drag (click and hold)
					if event.button_index == MOUSE_BUTTON_LEFT:
						print("🖱️ Chuột trái pressed: Bắt đầu drag item:", current_item.item_name)
						start_drag_item()
					# Chuột phải: trả về inventory ngay lập tức
					else:
						print("🖱️ Chuột phải: Trả item về inventory:", current_item.item_name)
						return_item_to_inventory(current_item)
						current_item = null
						is_filled = false
						$ItemIcon.texture = null
						$ItemIcon.visible = false

						var puzzle_ui = get_puzzle_ui()
						if puzzle_ui and puzzle_ui.has_method("check_all_slots_filled"):
							puzzle_ui.check_all_slots_filled()

			# Mouse button released (end drag if dragging)
			else:
				# Chỉ xử lý left mouse release khi đang drag
				if event.button_index == MOUSE_BUTTON_LEFT and UserInterface.is_dragging and UserInterface.holding_item:
					print("🖱️ Chuột trái released: Kết thúc drag")
					end_drag_item(event.global_position)

func process_drop(held_item: Node, drop_position: Vector2):
	print("🔍 process_drop called on", name, "with held_item:", held_item, "item_name:", held_item.item_name if held_item else "null", "at position:", drop_position)
	if held_item and not is_filled:
		print("🔍 Checking item:", held_item.item_name, "against expected:", expected_item)
		if held_item.item_name == expected_item:
			var texture_rect = held_item.get_node_or_null("TextureRect")
			if texture_rect and texture_rect.texture:
				var item_texture = texture_rect.texture.duplicate()
				print("✅ Đặt đúng item:", held_item.item_name, "vào", name, "Texture:", item_texture)
				$ItemIcon.texture = item_texture
				$ItemIcon.visible = true
				$ItemIcon.size = size
				$ItemIcon.position = Vector2(0, 0)
				# Debug rendering properties
				print("ItemIcon after drop - Visible:", $ItemIcon.visible, "Size:", $ItemIcon.size, "Texture:", $ItemIcon.texture)

				# Store current item for drag functionality
				current_item = held_item
				add_child(held_item)
				held_item.visible = false
				held_item.position = Vector2.ZERO

				is_filled = true
				print("🔍 Set is_filled to true for", name)
				var puzzle_ui = get_puzzle_ui()
				if puzzle_ui:
					print("🔍 Calling check_all_slots_filled from", name)
					puzzle_ui.check_all_slots_filled()
				else:
					print("❌ Error: PuzzleUI not found for", name)
			else:
				print("❌ Error: No valid TextureRect or texture in held_item for", name)
		else:
			print("❌ Sai item:", held_item.item_name, "| Cần:", expected_item, "ở", name)

func receive_item(item):
	# Handle swapping if slot is already filled
	if is_filled:
		swap_items(item)
		return

	if item.item_name == expected_item:
		var texture_rect = item.get_node_or_null("TextureRect")
		if texture_rect and texture_rect.texture:
			var item_texture = texture_rect.texture.duplicate()
			print("✅ Received item:", item.item_name, "vào", name, "Texture:", item_texture)
			$ItemIcon.texture = item_texture
			$ItemIcon.visible = true
			$ItemIcon.size = size
			$ItemIcon.position = Vector2(0, 0)
			# Debug rendering properties
			print("ItemIcon after receive - Visible:", $ItemIcon.visible, "Size:", $ItemIcon.size, "Texture:", $ItemIcon.texture)

			# Store current item for drag functionality
			current_item = item
			add_child(item)
			item.visible = false
			item.position = Vector2.ZERO

			is_filled = true
			print("🔍 Set is_filled to true for", name)
			UserInterface.is_dragging = false

			var puzzle_ui = get_puzzle_ui()
			if puzzle_ui:
				print("🔍 Calling check_all_slots_filled from", name)
				puzzle_ui.check_all_slots_filled()
			else:
				print("❌ Error: PuzzleUI not found for", name)
		else:
			print("❌ Error: No valid TextureRect or texture in received item for", name)
	else:
		print("❌ Sai item:", item.item_name, "ở", name)

func get_puzzle_ui():
	var parent = get_parent()  # TrialPuzzle
	if parent:
		var puzzle_ui = parent.get_parent()  # PuzzleUI
		if puzzle_ui and puzzle_ui.name == "PuzzleUI":
			return puzzle_ui
		else:
			print("❌ Error: Parent of", parent.name, "is not PuzzleUI, found:", puzzle_ui.name if puzzle_ui else "null")
	else:
		print("❌ Error: No parent (TrialPuzzle) found for", name)
	return null

func get_user_interface():
	var puzzle_ui = get_puzzle_ui()
	if puzzle_ui:
		var user_interface = puzzle_ui.get_parent()  # UserInterface
		if user_interface and user_interface.name == "UserInterface":
			return user_interface
		else:
			print("❌ Error: Parent of PuzzleUI is not UserInterface, found:", user_interface.name if user_interface else "null")
	else:
		print("❌ Error: PuzzleUI not found when getting user_interface")
	return null

func swap_items(incoming_item: Control):
	if not current_item or not incoming_item:
		return



	# Store reference to existing item
	var existing_item = current_item

	# Clear current slot
	current_item = null
	is_filled = false
	$ItemIcon.texture = null
	$ItemIcon.visible = false

	# Remove existing item from this slot's children
	if existing_item.get_parent() == self:
		remove_child(existing_item)

	# Check if incoming item matches expected item
	if incoming_item.item_name == expected_item:
		var texture_rect = incoming_item.get_node_or_null("TextureRect")
		if texture_rect and texture_rect.texture:
			var item_texture = texture_rect.texture.duplicate()
			print("✅ Swapped in correct item:", incoming_item.item_name, "Texture:", item_texture)
			$ItemIcon.texture = item_texture
			$ItemIcon.visible = true
			$ItemIcon.size = size
			$ItemIcon.position = Vector2(0, 0)

			# Store current item for drag functionality
			current_item = incoming_item
			add_child(incoming_item)
			incoming_item.visible = false
			incoming_item.position = Vector2.ZERO

			is_filled = true
			print("🔍 Set is_filled to true for", name)
		else:
			print("❌ Error: No valid TextureRect or texture in incoming item for", name)
			return
	else:
		print("❌ Swapped in wrong item:", incoming_item.item_name, "| Cần:", expected_item, "ở", name)
		# Still allow swap but mark as wrong item
		var texture_rect = incoming_item.get_node_or_null("TextureRect")
		if texture_rect and texture_rect.texture:
			var item_texture = texture_rect.texture.duplicate()
			$ItemIcon.texture = item_texture
			$ItemIcon.visible = true
			$ItemIcon.size = size
			$ItemIcon.position = Vector2(0, 0)

			current_item = incoming_item
			add_child(incoming_item)
			incoming_item.visible = false
			incoming_item.position = Vector2.ZERO

			is_filled = true

	# Determine where to place the displaced item based on source
	var source_puzzle_slot = UserInterface.original_puzzle_slot
	var original_slot_index = UserInterface.original_slot_index
	var original_is_hotbar = UserInterface.original_is_hotbar



	# Case 1: Incoming item from another puzzle slot (bidirectional puzzle swap)
	if source_puzzle_slot and is_instance_valid(source_puzzle_slot) and source_puzzle_slot != self:
		# Check if source slot is empty or can receive the displaced item
		if not source_puzzle_slot.is_filled:
			# Source slot is empty, place displaced item there
			if source_puzzle_slot.has_method("receive_item"):
				source_puzzle_slot.receive_item(existing_item)
			elif source_puzzle_slot.has_method("process_drop"):
				source_puzzle_slot.process_drop(existing_item, Vector2.ZERO)
		else:
			# Source slot is occupied, this shouldn't happen in normal bidirectional swap
			# but handle it gracefully by returning to inventory
			return_item_to_inventory(existing_item)
	
	# Case 2: Incoming item from inventory (inventory-to-puzzle swap)
	elif original_slot_index >= 0:
		return_item_to_inventory_slot(existing_item, original_slot_index, original_is_hotbar)
	
	# Case 3: Fallback - return to general inventory
	else:
		return_item_to_inventory(existing_item)

	# Clear any dragging state since we're not dragging the displaced item
	UserInterface.holding_item = null
	UserInterface.is_dragging = false

	# Update puzzle state
	var puzzle_ui = get_puzzle_ui()
	if puzzle_ui and puzzle_ui.has_method("check_all_slots_filled"):
		puzzle_ui.check_all_slots_filled()

	# Defer UI refresh until after all operations complete to prevent conflicts
	call_deferred("deferred_ui_refresh")



func start_drag_item():
	if not current_item:
		return

	print("🔁 Bắt đầu drag item từ PuzzleSlotTrial:", current_item.item_name)

	# Hiện lại item để drag
	current_item.visible = true
	UserInterface.holding_item = current_item

	# Set original slot info để biết item đến từ puzzle slot
	UserInterface.original_slot_index = -1  # -1 indicates puzzle slot
	UserInterface.original_is_hotbar = false
	UserInterface.original_puzzle_slot = self  # Store reference to this puzzle slot

	# Clear slot
	current_item = null
	is_filled = false
	$ItemIcon.texture = null
	$ItemIcon.visible = false

	# Add item to DraggingLayer với z-index cao
	var dragging_layer = get_tree().get_current_scene().get_node_or_null("DraggingLayer")
	if dragging_layer:
		dragging_layer.add_child(UserInterface.holding_item)
	else:
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

	# Update puzzle state
	var puzzle_ui = get_puzzle_ui()
	if puzzle_ui and puzzle_ui.has_method("check_all_slots_filled"):
		puzzle_ui.check_all_slots_filled()

func end_drag_item(mouse_pos: Vector2):
	if not UserInterface.holding_item or not UserInterface.is_dragging:
		return

	print("🔚 Kết thúc drag tại vị trí:", mouse_pos)

	# Tìm slot hoặc inventory để drop item
	var dropped_successfully = false

	# Kiểm tra xem có drop vào puzzle slot khác không
	var puzzle_slots = []
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlotTrial")
	puzzle_slots += get_tree().get_nodes_in_group("PuzzleSlot")

	for puzzle_slot in puzzle_slots:
		if puzzle_slot != self and puzzle_slot is Control:
			var slot_rect = Rect2(puzzle_slot.global_position, puzzle_slot.size)
			if slot_rect.has_point(mouse_pos):
				# Check if slot is filled - if so, swap items
				if puzzle_slot.is_filled and puzzle_slot.has_method("swap_items"):
					puzzle_slot.swap_items(UserInterface.holding_item)
					# Note: swap_items handles UserInterface.holding_item and is_dragging internally
					dropped_successfully = true
					print("✅ Swapped với puzzle slot:", puzzle_slot.name)
					break
				# If slot is empty, try receive_item first
				elif not puzzle_slot.is_filled and puzzle_slot.has_method("receive_item"):
					puzzle_slot.receive_item(UserInterface.holding_item)
					UserInterface.holding_item = null
					UserInterface.is_dragging = false
					dropped_successfully = true
					print("✅ Dropped vào puzzle slot:", puzzle_slot.name)
					break
				# For trial slots, try process_drop
				elif not puzzle_slot.is_filled and puzzle_slot.has_method("process_drop"):
					puzzle_slot.process_drop(UserInterface.holding_item, mouse_pos)
					UserInterface.holding_item = null
					UserInterface.is_dragging = false
					dropped_successfully = true
					print("✅ Dropped vào trial puzzle slot:", puzzle_slot.name)
					break

	# Nếu không drop vào puzzle slot, thử drop vào inventory
	if not dropped_successfully:
		var inventory_system = get_tree().get_first_node_in_group("InventorySystem")
		if inventory_system and inventory_system.has_method("try_drop_item"):
			inventory_system.try_drop_item(null, mouse_pos)
			dropped_successfully = true
			print("✅ Dropped vào inventory system")

	# Nếu vẫn không drop được, trả về inventory
	if not dropped_successfully and UserInterface.holding_item:
		print("⚠️ Không thể drop, trả về inventory")
		return_item_to_inventory(UserInterface.holding_item)
		UserInterface.holding_item = null
		UserInterface.is_dragging = false

func return_item_to_inventory(item: Control):
	print("📤 [CRAFT_RETURN] return_item_to_inventory called:")
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
		print("⚠ Không có chỗ trống, vứt ra ngoài")
		get_tree().get_root().add_child(item)
		item.visible = true
		item.global_position = get_global_mouse_position()
	else:
		print("✅ Successfully returned to general inventory")

func clear_slot():
	$ItemIcon.texture = null
	$ItemIcon.visible = false
	current_item = null
	is_filled = false

func return_item_to_inventory_slot(item: Control, slot_index: int, is_hotbar: bool):
	"""Return item to specific inventory slot to maintain proper swap behavior"""
	if not item or not is_instance_valid(item):
		return

	# Remove from current parent
	if item.get_parent():
		item.get_parent().remove_child(item)

	# Find target slot
	var target_slot = null
	if is_hotbar:
		# Find hotbar slot
		var hotbar_slots = get_tree().get_nodes_in_group("HotbarSlot")
		for slot in hotbar_slots:
			if slot.slot_index == slot_index:
				target_slot = slot
				break
	else:
		# Find inventory slot
		var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")
		for slot in inventory_slots:
			if slot.slot_index == slot_index and not slot.is_hotbar_slot:
				target_slot = slot
				break

	if target_slot:
		# Check if target slot is empty
		if not target_slot.item:
			# Place item directly in the original slot
			target_slot.putIntoSlot(item)
			
			# Skip immediate UI refresh to prevent conflicts during swap
		else:
			# Original slot is occupied, clear original info to prevent infinite recursion
			UserInterface.original_slot_index = -1
			UserInterface.original_is_hotbar = false
			UserInterface.original_puzzle_slot = null
			return_item_to_inventory(item)
	else:
		# Slot not found, clear original info to prevent infinite recursion
		UserInterface.original_slot_index = -1
		UserInterface.original_is_hotbar = false
		UserInterface.original_puzzle_slot = null
		return_item_to_inventory(item)

func force_refresh_inventory_ui():
	"""Force refresh inventory UI to show updated items"""
	print("🔄 [CRAFT_UI_REFRESH] Bắt đầu refresh inventory UI")
	
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
	
	print("✅ [CRAFT_UI_REFRESH] Hoàn tất refresh inventory UI")

func deferred_ui_refresh():
	"""Deferred UI refresh to ensure all swap operations complete first"""
	print("🔄 [CRAFT_DEFERRED_REFRESH] Starting deferred UI refresh")
	force_refresh_inventory_ui()
