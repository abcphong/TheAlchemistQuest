extends Panel
class_name PuzzleSlot

@export var expected_item: Array[String] = []
var is_filled := false
var current_item: Control = null  # Item hiện đang nằm trong slot

func _ready():
	add_to_group("PuzzleSlot")

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var held_item = UserInterface.holding_item

		# TH1: đang cầm item và slot trống → đặt vào (bất kể đúng sai)
		if held_item and not is_filled:
			# Đảm bảo item sẽ không bị mất nếu nhận thất bại
			if not receive_item(held_item):
				return
			UserInterface.holding_item = null

		# TH2: không cầm gì, và slot đã có item → kéo ra lại
		elif not held_item and current_item and is_filled:
			# ✅ Hiện lại item
			current_item.visible = true
			print("[DEBUG-DRAG] Picking up '", current_item.item_name, "' from puzzle slot '", self.name, "'")

			UserInterface.holding_item = current_item
			# Đặt thông tin về slot gốc
			UserInterface.original_puzzle_slot = self
			UserInterface.original_slot_index = -1
			UserInterface.original_is_hotbar = false
			
			current_item = null
			is_filled = false
			$ItemIcon.texture = null

			var parent = get_parent() if is_instance_valid(get_parent()) else get_tree().get_root()
			parent.add_child(UserInterface.holding_item)
			
			UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
			UserInterface.holding_item.set_z_as_relative(false)
			UserInterface.holding_item.z_index = 9999
			UserInterface.is_dragging = true

			if get_parent() and get_parent().has_method("check_all_slots_filled"):
				get_parent().check_all_slots_filled()
			
			# Cập nhật lại UI inventory
			update_inventory_ui()

func place_item_in_slot(item: Control):
	if not is_instance_valid(item):
		clear_slot()
		return
	
	# Đặt item mới vào slot
	current_item = item

	var tex_node = item.get_node_or_null("TextureRect")
	if tex_node:
		$ItemIcon.texture = tex_node.texture

	# Xử lý parenting
	var old_parent = item.get_parent()
	if old_parent:
		old_parent.remove_child(item)
	
	add_child(item)
	item.visible = false
	item.position = Vector2.ZERO

	is_filled = true

func clear_slot():
	if is_instance_valid(current_item):
		if current_item.get_parent() == self:
			remove_child(current_item)
	current_item = null
	is_filled = false
	$ItemIcon.texture = null

func receive_item(new_item: Control) -> bool:
	if not is_instance_valid(new_item):
		print("[DEBUG-DRAG] Puzzle slot '", self.name, "' receive failed: item is not valid.")
		return false

	print("[DEBUG-DRAG] Puzzle slot '", self.name, "' trying to receive '", new_item.item_name, "' (x", new_item.item_quantity, ")")

	if is_instance_valid(UserInterface.original_puzzle_slot):
		var source_slot = UserInterface.original_puzzle_slot
		print("[DEBUG-DRAG] Source is another puzzle slot '", source_slot.name, "'. Swapping.")
		if source_slot == self:
			place_item_in_slot(new_item)
			UserInterface.holding_item = null
			UserInterface.original_puzzle_slot = null
		else:
			var item_from_this_slot = self.current_item
			place_item_in_slot(new_item)
			if is_instance_valid(item_from_this_slot):
				source_slot.place_item_in_slot(item_from_this_slot)
			else:
				source_slot.clear_slot()
			UserInterface.holding_item = null
			UserInterface.original_puzzle_slot = null
			if source_slot.get_parent() and source_slot.get_parent().has_method("check_all_slots_filled"):
				source_slot.get_parent().check_all_slots_filled()
	else:
		print("[DEBUG-DRAG] Source is inventory.")
		var item_to_return = self.current_item
		place_item_in_slot(new_item)

		# If there was an item in the slot, return it to the original inventory slot.
		if is_instance_valid(item_to_return):
			print("[DEBUG-DRAG] Swapping. Returning '", item_to_return.item_name, "' to original inventory slot.")
			
			# Find the original slot the player was dragging from
			var original_slot = null
			for inv_slot in get_tree().get_nodes_in_group("InventorySlot"):
				if inv_slot.slot_index == UserInterface.original_slot_index and inv_slot.is_hotbar_slot == UserInterface.original_is_hotbar:
					original_slot = inv_slot
					break
			
			if original_slot:
				print("[DEBUG-DRAG] Found original slot ", original_slot.slot_index, ". Placing item back directly.")
				if item_to_return.get_parent():
					item_to_return.get_parent().remove_child(item_to_return)
				original_slot.putIntoSlot(item_to_return)
			else:
				# Fallback in case the original slot cannot be found (should not happen)
				print("[ERROR] Could not find original inventory slot! Returning item generically.")
				if not UserInterface.return_item_to_inventory(item_to_return):
					print("[ERROR] Failed to return '", item_to_return.item_name, "' to inventory!")
		
		UserInterface.is_dragging = false

	if get_parent() and get_parent().has_method("check_all_slots_filled"):
		get_parent().check_all_slots_filled()
	
	# update_inventory_ui() # Đã chuyển logic này về inventory.gd để đảm bảo nó chạy sau cùng
	return true

func return_item_to_inventory(item: Control) -> bool:
	if not is_instance_valid(item):
		return true
		
	if item.get_parent():
		item.get_parent().remove_child(item)

	var success := UserInterface.return_item_to_inventory(item)

	if not success:
		# Nếu không thể trả về inventory, hiển thị item dưới con trỏ chuột để người chơi có cơ hội lấy lại
		get_tree().get_root().add_child(item)
		item.visible = true
		item.global_position = get_viewport().get_mouse_position()
		UserInterface.holding_item = item
		UserInterface.is_dragging = true
		return false  # Báo là không thành công trả về inventory

	current_item = null
	is_filled = false
	$ItemIcon.texture = null
	return true

# Hàm cập nhật lại UI inventory
func update_inventory_ui():
	# Cập nhật inventory nếu có
	var inventory_ui = get_tree().root.find_child("Inventory", true, false)
	if inventory_ui:
		inventory_ui.initialize_inventory()
	
	# Cập nhật hotbar nếu có
	var hotbar_ui = get_tree().root.find_child("Hotbar", true, false)
	if hotbar_ui:
		hotbar_ui.initialize_hotbar()

# Hàm thành viên để gọi hàm static
func return_all_items():
	PuzzleSlot.return_all_items_to_inventory(get_tree())

# Hàm để trả tất cả item từ tất cả puzzle slot về inventory
static func return_all_items_to_inventory(tree: SceneTree):
	# Tìm tất cả puzzle slot trong scene
	var puzzle_slots = []
	for node in tree.get_nodes_in_group("PuzzleSlot"):
		if node is PuzzleSlot:
			puzzle_slots.append(node)
	
	# Trả từng item về inventory
	for slot in puzzle_slots:
		if slot.is_filled and is_instance_valid(slot.current_item):
			# Lấy tham chiếu đến item instance
			var item_instance = slot.current_item
			
			# Xóa item khỏi slot
			slot.current_item = null
			slot.is_filled = false
			slot.get_node("ItemIcon").texture = null
			if item_instance.get_parent() == slot:
				slot.remove_child(item_instance)

			# Trả item về inventory bằng hàm chuyên dụng
			var ui = tree.get_first_node_in_group("UserInterface")
			if ui and ui.has_method("return_item_to_inventory"):
				# Hàm này sẽ xử lý việc thêm lại vào PlayerInventory và xóa instance
				ui.return_item_to_inventory(item_instance)
			else:
				# Fallback an toàn: tự thêm vào PlayerInventory và xóa instance
				PlayerInventory.add_item(item_instance.item_name, item_instance.item_quantity)
				item_instance.queue_free()
	
	# Cập nhật UI
	var inventory_ui = tree.root.find_child("Inventory", true, false)
	if inventory_ui:
		inventory_ui.initialize_inventory()
	
	var hotbar_ui = tree.root.find_child("Hotbar", true, false)
	if hotbar_ui:
		hotbar_ui.initialize_hotbar()
