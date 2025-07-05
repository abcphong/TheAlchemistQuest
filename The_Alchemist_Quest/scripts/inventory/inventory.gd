extends Node2D

const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/inventory_slot.gd")
@onready var inventory_slots = $GridContainer
@onready var popup_panel = $PopupPanel
@onready var popup_label = $PopupPanel/VBoxContainer/DescriptionLabel
@onready var item_name_label = $PopupPanel/VBoxContainer/ItemNameLabel

var is_dragging := false

func _ready():
	# Kết nối các sự kiện cho các slot trong inventory
	for inv_slot in inventory_slots.get_children():
		inv_slot.gui_input.connect(slot_gui_input.bind(inv_slot))
		inv_slot.add_to_group("InventorySlot")
	PlayerInventory.inventory_changed.connect(initialize_inventory)
	initialize_inventory()
	popup_panel.hide()

func is_puzzle_ui_active() -> bool:
	# Tìm tất cả các loại puzzle UI có thể có trong game
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if puzzle_ui and puzzle_ui.visible:
		return true
		
	var puzzle_ui_task1 = get_tree().get_current_scene().find_child("puzzle_ui_task1", true, false)
	if puzzle_ui_task1 and puzzle_ui_task1.visible:
		return true
		
	var lab_workbench = get_tree().get_current_scene().find_child("lab_workbench", true, false)
	if lab_workbench and lab_workbench.visible and lab_workbench.get("is_puzzle_active"):
		return true
		
	# Kiểm tra bất kỳ node nào trong nhóm "PuzzleSlot"
	var puzzle_slots = get_tree().get_nodes_in_group("PuzzleSlot")
	if puzzle_slots.size() > 0:
		for slot in puzzle_slots:
			if slot.visible and is_instance_valid(slot) and slot.is_inside_tree():
				return true
				
	return false

func initialize_inventory():
	var slots = $GridContainer.get_children()
	
	# Đầu tiên, xóa tất cả items hiện có trong slots
	for i in range(slots.size()):
		if slots[i].item:
			# Xóa item khỏi slot
			slots[i].item.queue_free()
			slots[i].item = null
	
	# Sau đó cấu hình và tạo lại các items
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
			slots[i].initialize_item("", 0) # Đảm bảo slot được làm sạch

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if UserInterface.holding_item == null and slot.item:
				# Lưu thông tin về slot gốc
				UserInterface.original_slot_index = slot.slot_index
				UserInterface.original_is_hotbar = slot.is_hotbar_slot
				
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
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Nếu puzzle UI đang mở, ưu tiên kiểm tra puzzle slots
	if is_puzzle_ui_active():
		for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
			if not puzzle_slot is Control:
				continue
				
			var rect := Rect2(puzzle_slot.global_position, puzzle_slot.size)
			if rect.has_point(mouse_pos):
				# Đối với puzzle_slot không phải SlotClass, không trả về
				return null
	
	# Sau đó mới kiểm tra inventory slots
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
			
	return null

func handle_puzzle_to_inventory_swap(inventory_slot: SlotClass):
	var held_item = UserInterface.holding_item
	# putIntoSlot trả về item đã có trong slot (nếu có)
	var item_to_swap_back = inventory_slot.putIntoSlot(held_item)

	# place_item_in_slot xử lý việc đặt item vào puzzle slot (kể cả khi item là null)
	if is_instance_valid(UserInterface.original_puzzle_slot):
		UserInterface.original_puzzle_slot.place_item_in_slot(item_to_swap_back)

	# Dọn dẹp trạng thái toàn cục
	UserInterface.holding_item = null
	UserInterface.original_puzzle_slot = null
	UserInterface.is_dragging = false
	
	# Cập nhật dữ liệu inventory cho slot vừa thả item vào
	inventory_slot.update_inventory_dict()

	# Sau khi tất cả logic xử lý xong, làm mới toàn bộ inventory
	initialize_inventory()

func try_drop_item(slot: Node, mouse_pos: Vector2):
	var held_item_name = UserInterface.holding_item.item_name if is_instance_valid(UserInterface.holding_item) else "None"
	print("[DEBUG-DRAG] try_drop_item called. Held item: '", held_item_name, "'")
	
	# Trường hợp thả vào một inventory slot cụ thể
	if slot is SlotClass and slot.get_global_rect().has_point(mouse_pos):
		print("[DEBUG-DRAG] Target: Inventory Slot ", slot.slot_index)
		# TH1: Item đến từ PuzzleSlot
		if is_instance_valid(UserInterface.original_puzzle_slot):
			var held_item = UserInterface.holding_item
			var target_slot = slot as SlotClass
			
			if not target_slot.item:
				# Case A: Dropping into an empty slot
				print("[DEBUG-DRAG] Puzzle->Inv: Dropping '", held_item.item_name, "' into empty slot ", target_slot.slot_index)
				target_slot.putIntoSlot(held_item)
				UserInterface.holding_item = null
				UserInterface.original_puzzle_slot = null
			elif target_slot.item.item_name == held_item.item_name:
				# Case B: Dropping onto a stack of the same item
				print("[DEBUG-DRAG] Puzzle->Inv: Merging '", held_item.item_name, "' into existing stack.")
				# The held item from a puzzle slot is always quantity 1.
				var remaining_quantity = target_slot.item.add_item_quantity(1)
				
				# IMPORTANT: Sync data layer with the change
				target_slot.update_inventory_dict()
				
				if remaining_quantity > 0:
					# This case should be rare (stack is full), but if it happens, return the item.
					print("[ERROR] Puzzle->Inv: Stack is full. Returning item to puzzle slot.")
					UserInterface.original_puzzle_slot.place_item_in_slot(held_item)
					UserInterface.holding_item = null
				else:
					# Item was successfully merged, free the held item node.
					held_item.queue_free()
					UserInterface.holding_item = null
			else:
				# Case C: Swapping with a different item
				print("[DEBUG-DRAG] Puzzle->Inv: Swapping '", held_item.item_name, "' with '", target_slot.item.item_name, "'")
				handle_puzzle_to_inventory_swap(target_slot)

			initialize_inventory()
			return

		# TH2: Item đến từ InventorySlot (logic cũ)
		if !slot.item:
			left_click_empty_slot(slot)
		elif slot.item.item_name == UserInterface.holding_item.item_name:
			left_click_same_item(slot)
		else:
			left_click_different_item(null, slot)
		return

	# Trường hợp thả vào một puzzle slot
	for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
		if puzzle_slot is Control and puzzle_slot.get_global_rect().has_point(mouse_pos):
			print("[DEBUG-DRAG] Target: Puzzle Slot '", puzzle_slot.name, "'")
			var held_item = UserInterface.holding_item
			
			# Tạo một item mới với số lượng là 1
			var single_item = held_item.duplicate() # duplicate() có thể không sao chép script, cần kiểm tra
			single_item.set_script(held_item.get_script())
			single_item.set_item(held_item.item_name, 1)

			# Thử đưa item đơn lẻ vào puzzle slot
			if puzzle_slot.receive_item(single_item):
				print("[DEBUG-DRAG] Puzzle slot accepted. Remaining held quantity: ", held_item.item_quantity)
				# Nếu thành công, ta không còn "cầm" item nữa, nhưng node vẫn tồn tại trong held_item
				# Null out global state immediately to avoid confusion.
				UserInterface.holding_item = null

				# Giảm số lượng của node item mà ta đang giữ tham chiếu
				held_item.decrease_item_quantity(1)
				# KHÔNG cập nhật slot gốc. Nó đã được làm trống khi nhặt lên và có thể đã được sử dụng.
				# PlayerInventory.update_item_quantity(UserInterface.original_slot_index, held_item.item_quantity, UserInterface.original_is_hotbar)

				# Nếu node item hết sạch, xóa nó đi
				if held_item.item_quantity <= 0:
					held_item.queue_free() # Dùng held_item, không dùng UserInterface.holding_item
				else:
					# Nếu vẫn còn, trả nó về inventory. Hàm này sẽ xử lý node.
					UserInterface.return_item_to_inventory(held_item)
					UserInterface.holding_item = null
			
			# Sau khi tất cả logic xử lý xong, làm mới toàn bộ inventory
			initialize_inventory()
			return
	
	print("[DEBUG-DRAG] Target: Dropped outside any valid slot. Returning item.")
	# Trường hợp thả ra ngoài (không phải slot hợp lệ)
	# Trả item về vị trí ban đầu
	if is_instance_valid(UserInterface.original_puzzle_slot):
		UserInterface.original_puzzle_slot.place_item_in_slot(UserInterface.holding_item)
	else:
		var success = UserInterface.return_item_to_inventory(UserInterface.holding_item)
		if not success:
			# Nếu không trả về được inventory (ví dụ: đầy), thì xóa item
			drop_item_to_world(UserInterface.holding_item)

	# Dọn dẹp trạng thái
	UserInterface.holding_item = null
	UserInterface.original_puzzle_slot = null
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false

func drop_item_to_world(item):
	if item and is_instance_valid(item):
		item.queue_free()

func handle_right_click(event: InputEvent, slot: SlotClass):
	# Hàm này không còn cần thiết vì chúng ta đã chuyển sang hover
	pass

func show_description_popup(description: String, position: Vector2, item_name: String = "Item"):
	item_name_label.text = item_name
	popup_label.text = description
	popup_panel.global_position = position + Vector2(20, 20)
	popup_panel.show()

func _input(event):
	# Luôn cập nhật vị trí của item đang cầm theo chuột nếu có
	if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()

	# Khi nhả chuột trái, xử lý thả item
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
			var hovered_slot = get_slot_under_mouse()
			try_drop_item(hovered_slot, event.global_position)
			UserInterface.is_dragging = false
	
	# Khi nhả chuột phải, xử lý thả item (cho item được lấy bằng chuột phải)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
			var hovered_slot = get_slot_under_mouse()
			try_drop_item(hovered_slot, event.global_position)
			UserInterface.is_dragging = false

	# DEBUG: Add items for testing
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_T:
			var success = PlayerInventory.add_item("Copper wire", 5)
			if success:
				print("DEBUG: Added 5 Copper wire to inventory.")
			else:
				print("DEBUG: Failed to add Copper wire (inventory full?).")
			get_viewport().set_input_as_handled()

func left_click_empty_slot(slot: SlotClass):
	# Nếu item đến từ puzzle slot, ta không muốn làm gì ở đây vì đã được xử lý
	if is_instance_valid(UserInterface.original_puzzle_slot):
		# Có thể đặt lại item vào puzzle slot nếu cần
		UserInterface.original_puzzle_slot.place_item_in_slot(UserInterface.holding_item)
		UserInterface.holding_item = null
		UserInterface.original_puzzle_slot = null
		return
		
	slot.putIntoSlot(UserInterface.holding_item)
	PlayerInventory.add_item_to_empty_slot(UserInterface.holding_item, slot)
	UserInterface.holding_item = null
	# Reset thông tin về slot gốc
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false

func left_click_same_item(slot: SlotClass):
	# Nếu item đến từ puzzle slot, không gộp stack, chỉ hoán đổi
	if is_instance_valid(UserInterface.original_puzzle_slot):
		handle_puzzle_to_inventory_swap(slot)
		return

	var held_item = UserInterface.holding_item
	var slot_item = slot.item
	
	var remaining_quantity = slot_item.add_item_quantity(held_item.item_quantity)
	
	PlayerInventory.update_item_quantity(slot.slot_index, slot_item.item_quantity, slot.is_hotbar_slot)
	
	if remaining_quantity > 0:
		held_item.set_item_quantity(remaining_quantity)
		# Since we are still holding an item, we need to update its data in the original slot in PlayerInventory
		# This assumes the original slot info is still valid in UserInterface
		if UserInterface.original_slot_index != -1:
			PlayerInventory.update_item_quantity(UserInterface.original_slot_index, remaining_quantity, UserInterface.original_is_hotbar)
	else:
		UserInterface.holding_item.queue_free()
		UserInterface.holding_item = null
		# The original slot is now empty
		if UserInterface.original_slot_index != -1:
			PlayerInventory.remove_item(UserInterface.original_slot_index, UserInterface.original_is_hotbar)
		# Reset thông tin về slot gốc
		UserInterface.original_slot_index = -1
		UserInterface.original_is_hotbar = false

func left_click_different_item(from_slot: SlotClass, to_slot: SlotClass):
	# Nếu item đến từ puzzle slot, ta không muốn hoán đổi với inventory, chỉ trả lại
	if is_instance_valid(UserInterface.original_puzzle_slot):
		handle_puzzle_to_inventory_swap(to_slot)
		return

	var held_item = UserInterface.holding_item
	
	# Tìm slot gốc
	var original_slot = null
	for inv_slot in get_tree().get_nodes_in_group("InventorySlot"):
		if inv_slot.slot_index == UserInterface.original_slot_index and inv_slot.is_hotbar_slot == UserInterface.original_is_hotbar:
			original_slot = inv_slot
			break
			
	if original_slot:
		var item_to_swap = to_slot.pickFromSlot()
		to_slot.putIntoSlot(held_item)
		original_slot.putIntoSlot(item_to_swap)
	
	# Dọn dẹp trạng thái
	UserInterface.holding_item = null
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false
	
	# Cập nhật lại toàn bộ UI
	initialize_inventory()

func _on_popup_panel_visibility_changed():
	pass

# Hàm cập nhật lại toàn bộ UI
func update_ui():
	# Cập nhật inventory
	initialize_inventory()
	
	# Cập nhật hotbar nếu có
	var hotbar_ui = get_tree().root.find_child("Hotbar", true, false)
	if hotbar_ui:
		hotbar_ui.initialize_hotbar()
	
	# Lấy lại focus cho inventory để tránh bị treo
	$GridContainer.grab_focus()
