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

func try_drop_item(slot: Node, mouse_pos: Vector2):
	# Kiểm tra xem Puzzle UI có đang mở không
	var puzzle_ui_active = is_puzzle_ui_active()
	if puzzle_ui_active:
		# Khi puzzle UI đang mở, luôn kiểm tra PuzzleSlot trước
		var found_puzzle_slot = false
		for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
			if not puzzle_slot is Control:
				continue
			var rect := Rect2(puzzle_slot.global_position, puzzle_slot.size)
			
			if rect.has_point(mouse_pos):
				found_puzzle_slot = true
				puzzle_slot.receive_item(UserInterface.holding_item)
				UserInterface.holding_item = null
				return
	
	# Nếu không tìm thấy puzzle slot hoặc puzzle UI không mở
	if slot == null:
		# Kiểm tra PuzzleSlot lần nữa nếu chưa kiểm tra
		if not puzzle_ui_active:
			for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
				if not puzzle_slot is Control:
					continue
				var rect := Rect2(puzzle_slot.global_position, puzzle_slot.size)
				
				if rect.has_point(mouse_pos):
					puzzle_slot.receive_item(UserInterface.holding_item)
					UserInterface.holding_item = null
					return
		
		# Trả vật phẩm về inventory thay vì xóa
		var success = UserInterface.return_item_to_inventory(UserInterface.holding_item)
		if success:
			UserInterface.holding_item = null
		else:
			# Nếu không thể trả về inventory (hết chỗ), mới xóa
			drop_item_to_world(UserInterface.holding_item)
			UserInterface.holding_item = null
		return

	# Nếu puzzle UI đang mở, KHÔNG cho phép thả vào inventory slot
	if puzzle_ui_active:
		# Trả vật phẩm về vị trí cũ trong inventory
		var success = UserInterface.return_item_to_inventory(UserInterface.holding_item)
		if success:
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
		# Cập nhật phần này để khớp với xử lý ở trên
		var success = UserInterface.return_item_to_inventory(UserInterface.holding_item)
		if success:
			UserInterface.holding_item = null
		else:
			# Nếu không thể trả về inventory (hết chỗ), mới xóa
			drop_item_to_world(UserInterface.holding_item)
			UserInterface.holding_item = null

func drop_item_to_world(item):
	if item and is_instance_valid(item):
		item.queue_free()

func handle_right_click(event: InputEvent, slot: SlotClass):
	if is_puzzle_ui_active():
		return
		
	if slot.item:
		item_name_label.text = slot.item.item_name
		popup_label.text = JsonData.get_item_description(slot.item.item_name)
		popup_panel.global_position = get_viewport().get_mouse_position() + Vector2(20, 20)
		popup_panel.show()
		slot.modulate = Color(1, 0.8, 0)
		await get_tree().create_timer(0.1).timeout
		slot.modulate = Color(1, 1, 1)

func show_description_popup(description: String, position: Vector2, item_name: String = "Item"):
	if is_puzzle_ui_active():
		return
		
	item_name_label.text = item_name
	popup_label.text = description
	popup_panel.global_position = position + Vector2(20, 20)
	popup_panel.show()

func _input(event):
	if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if UserInterface.holding_item and is_instance_valid(UserInterface.holding_item):
			# Nếu puzzle UI đang mở, ưu tiên tìm kiếm puzzle slot
			if is_puzzle_ui_active():
				var found_puzzle_slot = false
				
				# Tìm puzzle slot dưới chuột
				for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
					if not puzzle_slot is Control:
						continue
					var rect := Rect2(puzzle_slot.global_position, puzzle_slot.size)
					if rect.has_point(event.global_position):
						puzzle_slot.receive_item(UserInterface.holding_item)
						UserInterface.holding_item = null
						found_puzzle_slot = true
						return
				
				# Nếu không tìm thấy puzzle slot, trả item về inventory
				if not found_puzzle_slot:
					var success = UserInterface.return_item_to_inventory(UserInterface.holding_item)
					if success:
						UserInterface.holding_item = null
					return
			
			# Nếu không phải puzzle UI hoặc không tìm thấy puzzle slot
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
		UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
		UserInterface.update_held_item_visibility()

func left_click_same_item(slot: SlotClass):
	if slot == null or slot.item == null or UserInterface.holding_item == null:
		return
		
	# Kiểm tra xem item có tồn tại trong JsonData không
	if not JsonData.item_data.has(slot.item.item_name):
		print("Lỗi: Item '" + slot.item.item_name + "' không tồn tại trong JsonData!")
		return
	
	var stack_size = int(JsonData.item_data[slot.item.item_name].get("StackSize", 99))
	var able_to_add = stack_size - slot.item.item_quantity
	
	if able_to_add >= UserInterface.holding_item.item_quantity:
		# Thực hiện thêm item vào slot hiện tại
		slot.item.add_item_quantity(UserInterface.holding_item.item_quantity)
		
		# Thêm vào PlayerInventory sau khi chắc chắn UI đã cập nhật thành công
		PlayerInventory.add_item_quantity(slot, UserInterface.holding_item.item_quantity)
		
		# Dọn dẹp item đang giữ
		UserInterface.holding_item.queue_free()
		UserInterface.holding_item = null
		initialize_inventory()  # Cập nhật lại inventory UI
	else:
		if able_to_add > 0:  # Nếu có thể thêm ít nhất một item
			slot.item.add_item_quantity(able_to_add)
			PlayerInventory.add_item_quantity(slot, able_to_add)
			UserInterface.holding_item.decrease_item_quantity(able_to_add)
		# Nếu không thể thêm item nào, không làm gì cả
		pass
