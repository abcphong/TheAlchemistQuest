extends CanvasLayer

var holding_item: Node = null
var inventory_node: Node2D
var save_load_ui: Control = null
var is_dragging := false
@onready var dragging_layer = get_tree().get_current_scene().get_node("DraggingLayer")

func _ready():
	layer = 10  # Đặt cao hơn các UI khác
	add_to_group("UserInterface")
	# Tìm SaveLoadUI khi game khởi động
	save_load_ui = get_tree().get_current_scene().find_child("SaveLoadUI", true, false)
	print("[DEBUG-UI] UserInterface khởi tạo thành công")

func update_held_item_visibility():
	if holding_item:
		holding_item.visible = true  # hoặc logic bạn mong muốn

func is_puzzle_ui_active() -> bool:
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if not puzzle_ui:
		puzzle_ui = get_tree().get_current_scene().find_child("puzzle_ui_task1", true, false)
	return puzzle_ui != null and puzzle_ui.visible

func toggle_inventory():
	# Không cho phép toggle inventory khi đang giải puzzle
	if is_puzzle_ui_active():
		print("[DEBUG-UI] Không thể mở inventory khi đang giải puzzle!")
		return
		
	if inventory_node:
		inventory_node.visible = not inventory_node.visible
		if inventory_node.visible:
			inventory_node.initialize_inventory()  # Cập nhật UI mỗi khi mở inventory

func toggle_save_load_menu():
	if save_load_ui:
		save_load_ui.toggle_visibility()
	else:
		print("[DEBUG-UI] Không tìm thấy SaveLoadUI!")

func _process(_delta):
	if is_dragging and holding_item:
		holding_item.global_position = get_viewport().get_mouse_position()
	
	# Xử lý phím tắt mở menu lưu/tải game
	if Input.is_action_just_pressed("toggle_save_menu"):
		toggle_save_load_menu()

func is_mouse_over_slot() -> bool:
	var mouse_pos = get_viewport().get_mouse_position()
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.get_global_rect().has_point(mouse_pos):
			return true
	return false

func drop_item_to_world(item):
	print("[DEBUG-UI] Vứt item ra ngoài: ", item.item_name)
	item.queue_free()

func get_slot_under_mouse() -> InventorySlot:
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
	return null
	
func return_item_to_inventory(item: Control) -> bool:
	# Kiểm tra null
	if not is_instance_valid(item):
		return false
	
	# Backup item info trước khi xử lý
	var item_name = item.item_name
	var item_quantity = item.item_quantity
	
	# Thay đổi thứ tự ưu tiên:
	# 1. Tìm slot trống trong Inventory TRƯỚC (không phải hotbar)
	var inventory_slots := get_tree().get_nodes_in_group("InventorySlot")
	inventory_slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)
	
	for slot in inventory_slots:  
		if not slot.is_hotbar_slot and slot.item == null:
			# Clone item trước khi xóa reference
			if item.get_parent():
				item.get_parent().remove_child(item)
			
			slot.initialize_item(item_name, item_quantity)
			
			# Queue free item cũ sau khi đã xử lý xong
			item.queue_free()
			return true
			
	# 2. Nếu inventory đầy, mới tìm slot trống trong Hotbar (ưu tiên sau)
	for slot in inventory_slots:
		if slot.is_hotbar_slot and slot.item == null:
			# Clone item trước khi xóa reference
			if item.get_parent():
				item.get_parent().remove_child(item)
				
			slot.initialize_item(item_name, item_quantity)
			
			# Queue free item cũ sau khi đã xử lý xong
			item.queue_free()
			return true

	# 3. Cảnh báo nếu không còn chỗ - lúc này giữ item lại cho người chơi
	
	# Nếu item còn valid, đảm bảo nó vẫn hiển thị để người chơi có thể thả vào chỗ khác
	if is_instance_valid(item):
		# Nếu parent không phải là scene root, thử chuyển nó ra để hiển thị
		if item.get_parent() != get_tree().get_root():
			if item.get_parent():
				item.get_parent().remove_child(item)
			get_tree().get_root().add_child(item)
			
		item.visible = true
		item.global_position = get_viewport().get_mouse_position()
		
		# Đặt item làm holding_item để người chơi có thể kéo nó
		holding_item = item
		is_dragging = true
	
	return false

func add_new_item_to_inventory(item_name: String, quantity: int) -> bool:
	print("[DEBUG-UI] Bắt đầu thêm item mới: ", item_name, " x ", quantity)
	
	var item_scene = load("res://The_Alchemist_Quest/scences/player/item.tscn")
	if item_scene == null:
		print("[DEBUG-UI] Không thể tải item scene!")
		return false

	var item_instance = item_scene.instantiate()
	item_instance.set_item(item_name, quantity)
	print("[DEBUG-UI] Đã tạo instance mới cho item: ", item_name)

	var inventory_slots := get_tree().get_nodes_in_group("InventorySlot")
	print("[DEBUG-UI] Số lượng inventory slots: ", inventory_slots.size())
	inventory_slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)

	# Kiểm tra xem JsonData có item này không
	var has_item_data = false
	if JsonData.item_data.has("item") and JsonData.item_data["item"].has(item_name):
		has_item_data = true
		print("[DEBUG-UI] Tìm thấy dữ liệu item trong JsonData['item'][", item_name, "]")
	elif JsonData.item_data.has(item_name):
		has_item_data = true
		print("[DEBUG-UI] Tìm thấy dữ liệu item trong JsonData[", item_name, "]")
	else:
		print("[DEBUG-UI] Không tìm thấy dữ liệu cho item: ", item_name, " trong JsonData!")

	# Ưu tiên thêm vào hotbar trước
	for slot in inventory_slots:
		if slot.is_hotbar_slot and slot.item == null:
			print("[DEBUG-UI] Thêm ", item_name, " vào hotbar slot ", slot.slot_index)
			slot.initialize_item(item_name, quantity)
			return true

	# Sau đó thêm vào inventory thường
	for slot in inventory_slots:
		if not slot.is_hotbar_slot and slot.item == null:
			print("[DEBUG-UI] Thêm ", item_name, " vào inventory slot ", slot.slot_index)
			slot.initialize_item(item_name, quantity)
			return true
	
	# Nếu inventory đầy, tạo item cho người chơi cầm tạm thời
	print("[DEBUG-UI] Không có slot trống, thêm ", item_name, " làm holding_item")
	item_instance.visible = true
	get_tree().get_root().add_child(item_instance)
	item_instance.global_position = get_viewport().get_mouse_position()
	holding_item = item_instance
	is_dragging = true
	
	return false
