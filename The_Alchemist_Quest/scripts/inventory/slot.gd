extends Panel

class_name InventorySlot 

var ItemClass = preload("res://The_Alchemist_Quest/scenes/player/item.tscn")
var item: Control = null
var item_data = {}
var slot_index = -1 
var is_hotbar_slot := false
var is_puzzle_ui := false
var is_showing_popup := false
var inventory_ref = null

@onready var popup_panel = get_node("../../PopupPanel")
@onready var popup_label = get_node("../../PopupPanel/VBoxContainer/DescriptionLabel")
@onready var item_name_label = get_node("../../PopupPanel/VBoxContainer/ItemNameLabel")
@onready var item_image_rect = get_node("../../PopupPanel/VBoxContainer/ItemImageRect")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	add_to_group("InventorySlot")

func check_puzzle_ui_status():
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if puzzle_ui == null:
		puzzle_ui = get_tree().get_current_scene().find_child("puzzle_ui_task1", true, false)
	
	# Nếu không tìm thấy, kiểm tra các loại puzzle UI khác
	if puzzle_ui == null:
		puzzle_ui = get_tree().get_current_scene().find_child("puzzle_ui_task_1", true, false)
	
	if puzzle_ui == null:
		puzzle_ui = get_tree().get_current_scene().find_child("LockingSystemUI", true, false)
	
	if puzzle_ui == null:
		puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUiTask2", true, false)
	
	if puzzle_ui == null:
		puzzle_ui = get_tree().get_current_scene().find_child("lab_workbench", true, false)
		if puzzle_ui != null and puzzle_ui.has_method("is_puzzle_active"):
			if not puzzle_ui.is_puzzle_active():
				puzzle_ui = null
	
	# Kiểm tra xem puzzle UI có visible và đang hoạt động không
	if puzzle_ui != null and puzzle_ui.visible:
		is_puzzle_ui = true
	else:
		is_puzzle_ui = false
		
func initialize_item(item_name: String, item_quantity: int):
	# SAFETY CHECK: Don't destroy item if it's currently being dragged
	if item and is_item_being_dragged(item):
		return

	#Clear existing item (only if not being dragged)
	if item:
		remove_child(item)
		item.queue_free()
		item = null

	#Create item if valid
	if item_name != "" and item_name != null  and item_quantity > 0:
		item = ItemClass.instantiate()
		add_child(item)
		item.set_item(item_name, item_quantity)
		item.position = Vector2(0, 0)
		item.name = "InventoryItem"

		update_inventory_dict()

# SAFETY FUNCTION: Check if item is being dragged
func is_item_being_dragged(check_item: Control) -> bool:
	if not check_item or not is_instance_valid(check_item):
		return false

	return UserInterface.holding_item == check_item

func _on_gui_input(event: InputEvent):
	# Right-click hold: take 1 item from stack while holding
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# Start holding item when right mouse pressed
			if item and item.item_quantity > 0 and UserInterface.holding_item == null:
				create_right_click_hold_item()
				get_viewport().set_input_as_handled()
		else:
			# Release item back to slot when right mouse released
			if UserInterface.holding_item and UserInterface.is_right_click_holding:
				return_right_click_item()
				get_viewport().set_input_as_handled()

func create_right_click_hold_item():
	# Do nothing if no item or player already holding an item
	if not item or UserInterface.holding_item != null:
		return

	# Store original item info for restoration
	UserInterface.right_click_original_slot = self
	UserInterface.right_click_original_item_name = item.item_name
	UserInterface.right_click_original_quantity = item.item_quantity

	# Instantiate new item with quantity 1
	var new_item = ItemClass.instantiate()
	new_item.set_item(item.item_name, 1)

	# Temporarily decrease quantity in current slot (will be restored on release)
	item.decrease_item_quantity(1)
	update_inventory_dict()

	# Temporarily remove item if quantity zero (will be restored on release)
	if item.item_quantity <= 0:
		item.visible = false  # Hide instead of destroying

	# Add new item to player's hand
	var ui_controller = get_tree().get_first_node_in_group("UserInterface")
	if not ui_controller:
		ui_controller = get_tree().get_root()
	ui_controller.add_child(new_item)

	# Configure new item position and z-index
	new_item.global_position = get_global_mouse_position()
	new_item.set_z_as_relative(false)
	new_item.z_index = 9999

	# Update player UI state
	UserInterface.holding_item = new_item
	UserInterface.is_right_click_holding = true
	UserInterface.is_dragging = true

func return_right_click_item():
	# Try to place item in nearest empty slot, fallback to original slot
	if not UserInterface.holding_item or not UserInterface.is_right_click_holding:
		return

	var held_item = UserInterface.holding_item
	var mouse_pos = get_viewport().get_mouse_position()

	# Try to find nearest empty slot
	var nearest_slot = find_nearest_empty_slot(mouse_pos)

	if nearest_slot and nearest_slot.slot_index >= 0:
		# Place item in nearest empty slot
		print("[DEBUG-SLOT] Placing item in nearest empty slot: ", nearest_slot.slot_index)
		# Remove held item from UI
		held_item.get_parent().remove_child(held_item)

		# Place in nearest slot
		nearest_slot.putIntoSlot(held_item)

		# Update inventory data (only inventory slots, not hotbar)
		PlayerInventory.inventory[nearest_slot.slot_index] = [held_item.item_name, held_item.item_quantity]

		UserInterface.holding_item = null
	else:
		# No empty slot found or invalid slot, return to original slot
		if nearest_slot:
			print("[DEBUG-SLOT] Found slot but invalid slot_index: ", nearest_slot.slot_index, " - destroying item")
		else:
			print("[DEBUG-SLOT] No empty slot found, destroying item")
		# Remove the held item
		held_item.queue_free()
		UserInterface.holding_item = null

		# Restore original item in slot
		var original_slot = UserInterface.right_click_original_slot
		if original_slot and is_instance_valid(original_slot):
			# Restore the item quantity
			if original_slot.item:
				original_slot.item.add_item_quantity(1)
				original_slot.item.visible = true
			else:
				# Recreate the item if it was completely removed
				original_slot.initialize_item(UserInterface.right_click_original_item_name, 1)

			original_slot.update_inventory_dict()

	# Reset UI state
	UserInterface.is_right_click_holding = false
	UserInterface.is_dragging = false
	UserInterface.right_click_original_slot = null
	UserInterface.right_click_original_item_name = ""
	UserInterface.right_click_original_quantity = 0

func find_nearest_empty_slot(mouse_position: Vector2):
	var nearest_slot = null
	var nearest_distance = INF

	# Check only inventory slots (exclude hotbar)
	var inventory_slots = get_tree().get_nodes_in_group("InventorySlot")

	for slot in inventory_slots:
		# Check if slot is effectively empty (no item, or item with 0 quantity, or hidden item)
		var is_slot_empty = (not slot.item) or (slot.item and slot.item.item_quantity <= 0) or (slot.item and not slot.item.visible)

		if is_slot_empty and not slot.is_hotbar_slot and is_instance_valid(slot) and slot.slot_index >= 0:  # Empty inventory slot only with valid index
			var slot_center = slot.global_position + slot.size / 2
			var distance = mouse_position.distance_to(slot_center)

			if distance < nearest_distance:
				nearest_distance = distance
				nearest_slot = slot

	return nearest_slot

# --- LOGIC HIỂN THỊ POPUP KHI HOVER ---
func _on_mouse_entered():
	# Show description on hover if not in puzzle UI
	check_puzzle_ui_status()
	# Chỉ hiển thị popup nếu slot có item
	if item and is_instance_valid(item) and popup_panel and not is_puzzle_ui:
		show_item_description()

func _on_mouse_exited():
	# Hide description popup
	# Ẩn popup khi chuột rời đi
	if popup_panel and popup_panel.visible:
		popup_panel.hide()
		is_showing_popup = false
	if popup_label:
		popup_label.visible = true

func show_item_description():
	if not item or not is_instance_valid(item):
		return
	
	var description = JsonData.get_item_description(item.item_name)
	_show_popup(item.item_name, description)

func _on_item_right_clicked(item_name: String, description: String):
	# This signal can be used if needed elsewhere
	_show_popup(item_name, description)

func _show_popup(item_name: String, description: String):
	if not item or not popup_panel:
		return

	# Lấy các node con của popup panel
	var item_name_label = popup_panel.get_node_or_null("VBoxContainer/ItemNameLabel")
	var item_image_rect = popup_panel.get_node_or_null("VBoxContainer/ItemImageRect")
	var popup_label = popup_panel.get_node_or_null("VBoxContainer/DescriptionLabel")

	# Kiểm tra xem tất cả các node có tồn tại không
	if not (item_name_label and item_image_rect and popup_label):
		return

	# 1. Cập nhật nội dung
	var item_name_description = item.item_name
	item_name_label.text = item_name
	popup_label.text = JsonData.get_item_description(item_name)
	
	# Tải ảnh cho item
	var image_path = "res://The_Alchemist_Quest/assets/item/%s.png" % item_name
	if ResourceLoader.exists(image_path):
		item_image_rect.texture = load(image_path)
	else:
		item_image_rect.texture = null # Xóa ảnh nếu không tìm thấy

	# 2. Định vị PopupPanel
	# Đặt vị trí của PopupPanel gần con trỏ chuột
	popup_panel.global_position = get_global_mouse_position() + Vector2(20, 20)

	# 3. Hiển thị PopupPanel
	popup_panel.show()


func update_inventory_dict():
	if slot_index == -1 or inventory_ref == null:
		print("⚠️ [UPDATE_DICT] Không thể update - slot_index:", slot_index, " inventory_ref:", inventory_ref)
		return
	
	print("📝 [UPDATE_DICT] Update inventory dict for slot ", slot_index, ":")
	print("  - Is hotbar slot: ", is_hotbar_slot)
	
	if item:
		print("  - Setting to: [", item.item_name, ", ", item.item_quantity, "]")
		inventory_ref[slot_index] = [item.item_name, item.item_quantity]
	else:
		# Set empty slot default values
		if is_hotbar_slot:
			print("  - Setting hotbar slot to empty: [\"\", 0]")
			inventory_ref[slot_index] = ["", 0]
		else:
			print("  - Setting inventory slot to empty: [null, 0]")
			inventory_ref[slot_index] = [null, 0]
	
	print("✅ [UPDATE_DICT] inventory_ref[", slot_index, "] = ", inventory_ref[slot_index])

func pickFromSlot() -> Control:
	print("🎯 [PICK_FROM_SLOT] pickFromSlot called on slot ", slot_index)
	print("  - Has item: ", item.item_name if item else "null")
	
	if item == null:
		print("  - No item to pick")
		return null
		
	var picked_item = item
	print("  - Removing item from slot: ", picked_item.item_name)
	remove_child(item)
	item = null
	
	print("  - Slot cleared, calling update_inventory_dict")
	update_inventory_dict()
	
	print("  - Slot item after clear: ", item)
	print("✅ [PICK_FROM_SLOT] Item picked successfully")
	return picked_item

func putIntoSlot(new_item: Control) -> Control:
	if new_item == null:
		print("❌ [SLOT_PUT] new_item is null")
		return null

	print("📥 [SLOT_PUT] Đặt item vào slot ", slot_index, ":")
	print("  - New item: ", new_item.item_name, " x", new_item.item_quantity)
	print("  - Is hotbar slot: ", is_hotbar_slot)
	if item:
		print("  - Old item: ", item.item_name, " x", item.item_quantity)

	# Remove from old parent if needed
	var old_parent = new_item.get_parent()
	if old_parent and old_parent != self:
		old_parent.remove_child(new_item)

	# Store old item to return
	var old_item = item
	
	# Remove old item from slot and clear reference properly
	if item:
		remove_child(item)
		item = null  # Clear reference immediately to prevent sync issues

	# Add new item to slot
	item = new_item
	add_child(item)
	item.position = Vector2.ZERO
	item.visible = true
	item.set_z_as_relative(false)
	item.z_index = 10
	item.name = "InventoryItem"
	
	print("  - Gọi update_inventory_dict()")
	update_inventory_dict()
	
	print("✅ [SLOT_PUT] Hoàn tất đặt item vào slot")
	return old_item

func is_mouse_over() -> bool:
	return get_slot_rect().has_point(get_viewport().get_mouse_position())

func get_slot_rect() -> Rect2:
	return Rect2(global_position, size)

func remove_item():
	if item:
		remove_child(item)
		item = null

func set_inventory_reference(ref):
	inventory_ref = ref
