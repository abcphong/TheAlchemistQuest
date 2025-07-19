extends Panel

class_name InventorySlot 

var ItemClass = preload("res://The_Alchemist_Quest/scences/player/item.tscn")
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
	#Clear existing item
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

func _on_gui_input(event: InputEvent):
	# Right-click: take 1 item from stack if possible
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if item and item.item_quantity > 0 and UserInterface.holding_item == null:
			create_right_click_item()
			get_viewport().set_input_as_handled()

func create_right_click_item():
	# Do nothing if no item or player already holding an item
	if not item or UserInterface.holding_item != null:
		return
	
	print("[DEBUG-RIGHTCLICK] Taking 1 item from stack...")
	
	# Instantiate new item with quantity 1
	var new_item = ItemClass.instantiate()
	new_item.set_item(item.item_name, 1)
	
	# Decrease quantity in current slot
	item.decrease_item_quantity(1)
	update_inventory_dict()
	
	# Remove item if quantity zero
	if item.item_quantity <= 0:
		item.queue_free()
		item = null
	
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
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false
	UserInterface.original_puzzle_slot = null
	UserInterface.is_dragging = true
	
	print("[DEBUG-RIGHTCLICK] Took 1 '", new_item.item_name, "' from stack")

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
		return
		
	if item:
		inventory_ref[slot_index] = [item.item_name, item.item_quantity]
	else:
		# Set empty slot default values
		if is_hotbar_slot:
			inventory_ref[slot_index] = ["", 0]
		else:
			inventory_ref[slot_index] = [null, 0]

func pickFromSlot() -> Control:
	if item == null:
		return null
		
	var picked_item = item
	print("[DEBUG-DRAG] Picking up '", picked_item.item_name, "' (x", picked_item.item_quantity, ") from slot ", slot_index)
	remove_child(item)
	item = null
	update_inventory_dict()
	return picked_item

func putIntoSlot(new_item: Control) -> Control:
	if new_item == null:
		return null

	# Remove from old parent if needed
	var old_parent = new_item.get_parent()
	if old_parent and old_parent != self:
		old_parent.remove_child(new_item)

	# Store old item to return
	var old_item = item
	
	# Remove old item from slot (keep for swap)
	if item:
		remove_child(item)

	# Add new item to slot
	item = new_item
	add_child(item)
	item.position = Vector2.ZERO
	item.visible = true
	item.set_z_as_relative(false)
	item.z_index = 10
	item.name = "InventoryItem"
	update_inventory_dict()
	
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
