extends Panel

class_name InventorySlot 

var ItemClass = preload("res://The_Alchemist_Quest/scences/player/item.tscn")
var item: Control = null
var item_data = {}
var slot_index = -1 
var is_hotbar_slot := false
var is_puzzle_ui := false
var is_showing_popup := false

@onready var popup_panel = get_node_or_null("../../PopupPanel")
@onready var popup_label = popup_panel.get_node_or_null("VBoxContainer/DescriptionLabel") if popup_panel else null
@onready var item_name_label = popup_panel.get_node_or_null("VBoxContainer/ItemNameLabel") if popup_panel else null
@onready var item_image_rect = popup_panel.get_node_or_null("VBoxContainer/ItemImageRect") if popup_panel else null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_to_group("InventorySlot")
	check_puzzle_ui_status()

func check_puzzle_ui_status():
	# Kiểm tra PuzzleUI hoặc puzzle_ui_task1 trong scene
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
	if item_name != "" and item_name != null and item_quantity > 0:
		item = ItemClass.instantiate()
		add_child(item)
		item.set_item(item_name, item_quantity)
		item.position = Vector2(0, 0)
		item.name = "InventoryItem"
		
		update_inventory_dict()

func _gui_input(event: InputEvent):
	# Xử lý chuột phải - lấy 1 item từ stack
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if item and item.item_quantity > 0 and UserInterface.holding_item == null:
			create_right_click_item()
			get_viewport().set_input_as_handled()

func create_right_click_item():
	# Không xử lý nếu đang không có item hoặc đã đang giữ item khác
	if not item or UserInterface.holding_item != null:
		return
	
	print("[DEBUG-RIGHTCLICK] Bắt đầu lấy 1 item từ stack...")
	
	# Tạo một item mới với số lượng là 1
	var new_item = ItemClass.instantiate()
	new_item.set_item(item.item_name, 1)
	
	# Giảm số lượng item trong slot hiện tại
	item.decrease_item_quantity(1)
	update_inventory_dict()
	
	# Nếu item hiện tại hết số lượng, xóa nó
	if item.item_quantity <= 0:
		item.queue_free()
		item = null
	
	# Đặt item mới vào tay người chơi
	var ui_controller = get_tree().get_first_node_in_group("UserInterface")
	if not ui_controller:
		ui_controller = get_tree().get_root()
		
	ui_controller.add_child(new_item)
	
	# Cấu hình item
	new_item.global_position = get_global_mouse_position()
	new_item.set_z_as_relative(false)
	new_item.z_index = 9999
	
	# Lưu trạng thái
	UserInterface.holding_item = new_item
	UserInterface.original_slot_index = -1
	UserInterface.original_is_hotbar = false
	UserInterface.original_puzzle_slot = null
	UserInterface.is_dragging = true
	
	print("[DEBUG-RIGHTCLICK] Đã lấy 1 '", new_item.item_name, "' từ stack")

func _on_mouse_entered():
	# Hiển thị mô tả khi di chuột vào nếu có item và không đang ở chế độ puzzle
	check_puzzle_ui_status() # Cập nhật trạng thái puzzle UI
	
	if item and is_instance_valid(item) and popup_panel != null and not is_puzzle_ui:
		show_item_description()

func _on_mouse_exited():
	# Ẩn mô tả khi di chuột ra
	if popup_panel and popup_panel.visible:
		popup_panel.hide()
		is_showing_popup = false
		
		# Đảm bảo các thành phần được reset về trạng thái mặc định
		if item_image_rect:
			item_image_rect.visible = false
			item_image_rect.texture = null
		if popup_label:
			popup_label.visible = true

func show_item_description():
	if !item or !is_instance_valid(item) or popup_panel == null:
		return
	
	# Kiểm tra xem có đang mở puzzle UI hay không
	check_puzzle_ui_status()
	
	# Nếu đang mở puzzle UI, không hiển thị mô tả
	if is_puzzle_ui:
		return
	
	var description = JsonData.get_item_description(item.item_name)
	_show_popup(item.item_name, description)

func _on_item_right_clicked(item_name: String, description: String):
	# Hàm này không còn cần thiết nhưng giữ lại để tránh lỗi
	pass

func _show_popup(item_name: String, description: String):
	# Kiểm tra null trước khi truy cập
	if popup_panel == null or item_name_label == null or popup_label == null or item_image_rect == null:
		return
		
	# Đặt lại trạng thái hiển thị
	popup_label.visible = true
	item_image_rect.visible = false
	item_image_rect.texture = null
		
	# Logic đặc biệt cho các vật phẩm dạng ghi chú
	if item_name == "Giấy Note":
		popup_label.visible = false # Ẩn mô tả chữ
		item_image_rect.visible = true # Hiện khu vực ảnh
		item_image_rect.texture = load("res://The_Alchemist_Quest/assets/gameDemo/Giấy Note.png")
		item_image_rect.custom_minimum_size = Vector2(150, 150)
	elif item_name == "Corrosion_reaction_note":
		popup_label.visible = false
		item_image_rect.visible = true
		item_image_rect.texture = load("res://The_Alchemist_Quest/assets/puzzle/storage_room/task1/Corrosion_reaction_note.png")
		item_image_rect.custom_minimum_size = Vector2(150, 150)
	elif item_name == "Note_Na2S2O3+H2O":
		popup_label.visible = false
		item_image_rect.visible = true
		item_image_rect.texture = load("res://The_Alchemist_Quest/assets/puzzle/storage_room/task2/Note_Na2S2O3+H2O.png")
		item_image_rect.custom_minimum_size = Vector2(150, 150)
	else:
		popup_label.text = description

	# Không kiểm tra puzzle UI status nữa để cho phép hiển thị popup khi đang giải puzzle
	item_name_label.text = item_name
	# Không cập nhật vị trí theo chuột nữa, giữ nguyên vị trí mặc định của popup
	popup_panel.show()
	is_showing_popup = true

func update_inventory_dict():
	if slot_index == -1:
		return
	var target_dict = PlayerInventory.hotbar if is_hotbar_slot else PlayerInventory.inventory
	if item:
		target_dict[slot_index] = [item.item_name, item.item_quantity]
	else:
		# When an item is removed, set it to the default empty state
		if is_hotbar_slot:
			target_dict[slot_index] = ["", 0]
		else:
			target_dict[slot_index] = [null, 0]

func pickFromSlot() -> Control :
	if item == null:
		return null
		
	var picked_item = item
	print("[DEBUG-DRAG] Picking up '", picked_item.item_name, "' (x", picked_item.item_quantity, ") from inventory slot ", slot_index)
	remove_child(item)
	item = null
	update_inventory_dict()
	
	return picked_item

func putIntoSlot(new_item: Control) -> Control:
	if new_item == null:
		return null

	# Remove from current parent
	var old_parent = new_item.get_parent()
	if old_parent and old_parent != self:
		old_parent.remove_child(new_item)

	# Lưu item cũ để trả về
	var old_item = item
	
	# Remove old item from slot (but don't destroy it)
	if item:
		remove_child(item)
		# KHÔNG gọi item.queue_free() ở đây để giữ item cho việc hoán đổi

	# Set and add new item
	item = new_item
	add_child(item)
	item.position = Vector2(0, 0)
	item.visible = true
	item.set_z_as_relative(false)
	item.z_index = 10
	item.name = "InventoryItem"
	update_inventory_dict()
	
	# Trả về item cũ (nếu có) để có thể hoán đổi
	return old_item

func is_mouse_over() -> bool:
	return get_slot_rect().has_point(get_viewport().get_mouse_position())

func get_slot_rect() -> Rect2:
	return Rect2(global_position, size)

func remove_item():
	remove_child(item)
	item = null
