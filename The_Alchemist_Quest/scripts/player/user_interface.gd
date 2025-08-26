extends CanvasLayer

var holding_item: Node = null
var inventory_node: Node2D
var is_dragging := false
var save_load_ui: Control = null
var original_slot_index := -1
var original_is_hotbar := false
var original_puzzle_slot = null

# Right-click hold variables
var is_right_click_holding := false
var right_click_original_slot = null
var right_click_original_item_name := ""
var right_click_original_quantity := 0
@onready var dragging_layer = get_tree().get_current_scene().get_node("DraggingLayer")

func _ready():
	layer = 16
	add_to_group("UserInterface")
	inventory_node = $InventoryContainer/Inventory
	find_save_load_ui()
	hide_inventory()
	
	# Kiểm tra flag từ homepage
	if get_tree().root.has_meta("show_save_ui_on_load") and get_tree().root.get_meta("show_save_ui_on_load"):
		get_tree().root.remove_meta("show_save_ui_on_load") # Xóa flag
		toggle_save_load_menu()


func find_save_load_ui() -> bool:
	# SaveLoadUI là child trực tiếp của UserInterface trong game scene
	save_load_ui = get_node_or_null("SaveLoadUI")
	if save_load_ui:
		print("[DEBUG-UI] Đã tìm thấy SaveLoadUI")
		return true
	else:
		print("[DEBUG-UI] Không tìm thấy SaveLoadUI, thử tìm trong scene tree")
		# Fallback: tìm trong toàn scene tree nếu không tìm thấy
		save_load_ui = get_tree().get_current_scene().find_child("SaveLoadUI", true, false)
		if save_load_ui:
			print("[DEBUG-UI] Đã tìm thấy SaveLoadUI trong scene tree")
			return true
		else:
			print("[DEBUG-UI] Không tìm thấy SaveLoadUI")
			return false

func update_held_item_visibility():
	if holding_item:
		holding_item.visible = true
		var texture_rect = holding_item.get_node_or_null("TextureRect")
		if texture_rect:
			texture_rect.visible = true
			print("✅ Holding item texture rect visible:", holding_item.item_name)
			
func is_puzzle_ui_active() -> bool:
	# Kiểm tra tất cả các loại puzzle UI có thể có
	var puzzle_ui_names = [
		"PuzzleUI", 
		"puzzle_ui_task1", 
		"puzzle_ui_task_1",
		"PuzzleUiTask1",
		"PuzzleUiTask2",
		"storage_puzzle_ui",
		"intro_puzzle_ui"
	]
	
	for ui_name in puzzle_ui_names:
		var puzzle_ui = get_tree().get_current_scene().find_child(ui_name, true, false)
		if puzzle_ui and puzzle_ui.visible:
			return true
	
	# Kiểm tra bằng cách tìm nodes trong group PuzzleSlot
	var puzzle_slots = get_tree().get_nodes_in_group("PuzzleSlot")
	for slot in puzzle_slots:
		if slot.visible and is_instance_valid(slot) and slot.is_inside_tree():
			return true
			
	return false
	
func toggle_save_load_menu():
	# Kiểm tra và tìm lại SaveLoadUI nếu cần
	if not is_instance_valid(save_load_ui):
		print("[DEBUG-UI] SaveLoadUI không còn hợp lệ, đang tìm lại...")
		if not find_save_load_ui():
			print("[DEBUG-UI] Không thể tìm thấy SaveLoadUI!")
			return
	
	# Kiểm tra thêm một lần nữa để đảm bảo an toàn
	if is_instance_valid(save_load_ui) and save_load_ui.has_method("toggle_visibility"):
		save_load_ui.toggle_visibility()
	else:
		print("[DEBUG-UI] SaveLoadUI không hợp lệ hoặc không có phương thức toggle_visibility!")

func toggle_inventory():
	# CHO PHÉP inventory hoạt động khi puzzle active để hỗ trợ drag/drop
	# Chỉ block khi có operations đang xung đột
	if is_puzzle_ui_active():
		print("[DEBUG-UI] Puzzle UI đang active - cho phép inventory nhưng với chế độ hạn chế")
		# Vẫn cho phép mở inventory nhưng với safe mode
		if inventory_node and holding_item:
			print("[DEBUG-UI] Đang hold item trong puzzle - cho phép inventory interaction")
		elif inventory_node and not inventory_node.visible:
			print("[DEBUG-UI] Mở inventory trong puzzle mode để hỗ trợ drag/drop")
		else:
			print("[DEBUG-UI] Inventory đã mở hoặc không cần thiết")
			return

	if inventory_node:
		inventory_node.visible = not inventory_node.visible
		if inventory_node.visible:
			# SAFE initialization - only if no drag operations active
			if not inventory_node.is_drag_operation_active():
				inventory_node.initialize_inventory()  # Cập nhật UI mỗi khi mở inventory
			else:
				print("[DEBUG-UI] Skipping inventory initialization - drag operation in progress")

func hide_inventory():
	if inventory_node:
		inventory_node.visible = false
		print("UserInterface hide_inventory called")

# Phương thức mới để force show inventory khi puzzle cần thiết
func force_show_inventory_for_puzzle():
	"""
	Force hiển thị inventory để hỗ trợ drag/drop với puzzle.
	Phương thức này bỏ qua các giới hạn thông thường.
	"""
	print("[DEBUG-UI] Force showing inventory for puzzle interaction")
	if inventory_node:
		inventory_node.visible = true
		# SAFE initialization - only if no drag operations active
		if not inventory_node.is_drag_operation_active():
			inventory_node.initialize_inventory()
		else:
			print("[DEBUG-UI] Skipping inventory initialization - drag operation in progress")
	else:
		print("[DEBUG-UI] Warning: inventory_node is null!")

func _process(_delta):
	if is_dragging and holding_item and is_instance_valid(holding_item):
		holding_item.global_position = get_viewport().get_mouse_position()

	# Handle right-click hold release when mouse button is no longer pressed
	if is_right_click_holding and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Find the original slot and return the item
		if right_click_original_slot and is_instance_valid(right_click_original_slot):
			right_click_original_slot.return_right_click_item()

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
	print("💥 Dropped item to world: ", item.item_name)
	item.queue_free()

func get_slot_under_mouse() -> InventorySlot:
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
	return null
	
func close_all_inventories():
	print("🔵 Closing all inventories")
	# Close regular inventory
	if inventory_node:
		print("🔵 Closing regular inventory")
		inventory_node.visible = false
	
	# Close any open puzzle UI (which contains workbench inventory)
	# But only if it's not the one we just created
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if puzzle_ui and is_instance_valid(puzzle_ui) and not puzzle_ui.is_queued_for_deletion():
		print("🔵 Closing existing puzzle UI")
		puzzle_ui.queue_free()


func is_any_inventory_open() -> bool:
	# Check if regular inventory is open
	if inventory_node and inventory_node.visible:
		return true
		
	# Check if puzzle UI (workbench inventory) is open
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if puzzle_ui and not puzzle_ui.is_queued_for_deletion():
		return true
		
	return false
	
func return_item_to_inventory(item: Control) -> bool:
	# Kiểm tra null
	if not is_instance_valid(item):
		return false
	
	# Lấy thông tin item
	var item_name = item.item_name
	var item_quantity = item.item_quantity
	
	print("[DEBUG-UI] Trả item về inventory: ", item_name, " x ", item_quantity)
	
	# Gọi hàm add_item của PlayerInventory làm nguồn chân lý
	var success = PlayerInventory.add_item(item_name, item_quantity)
	
	if success:
		print("[DEBUG-UI] Đã trả ", item_name, " về PlayerInventory thành công")
		
		# Xóa item cũ
		item.queue_free()
		
		# Cập nhật lại UI
		update_all_ui()
		return true
	else:
		print("[DEBUG-UI] Không thể trả ", item_name, " về PlayerInventory, giữ lại trên chuột")
		
		# Nếu không thể thêm vào inventory, giữ item trên chuột
		if item.get_parent() != get_tree().get_root():
			if item.get_parent():
				item.get_parent().remove_child(item)
			get_tree().get_root().add_child(item)
			
		item.visible = true
		item.global_position = get_viewport().get_mouse_position()
		holding_item = item
		is_dragging = true
	
	return false

func add_new_item_to_inventory(item_name: String, quantity: int) -> bool:
	print("[DEBUG-UI] Bắt đầu thêm item mới: ", item_name, " x ", quantity)
	
	# Gọi hàm add_item của PlayerInventory làm nguồn chân lý
	var success = PlayerInventory.add_item(item_name, quantity)
	
	if success:
		# Cập nhật lại UI
		update_all_ui()
		return true
	else:
		pass  # Create holding item if can't add to inventory
		
		# Nếu không thể thêm vào inventory, tạo item cho người chơi cầm tạm thời
		var item_scene = load("res://The_Alchemist_Quest/scenes/player/item.tscn")
		if item_scene == null:
			return false
			
		var item_instance = item_scene.instantiate()
		item_instance.set_item(item_name, quantity)
		
		item_instance.visible = true
		get_tree().get_root().add_child(item_instance)
		item_instance.global_position = get_viewport().get_mouse_position()
		holding_item = item_instance
		is_dragging = true
	
	return false

# Hàm tiện ích để cập nhật tất cả các UI liên quan đến inventory
func update_all_ui():
	# Cập nhật inventory UI nếu có
	var inventory_ui = get_tree().get_first_node_in_group("Inventory")
	if inventory_ui:
		inventory_ui.initialize_inventory()
	
	# Cập nhật hotbar UI nếu có
	var hotbar_ui = get_tree().get_first_node_in_group("Hotbar")
	if hotbar_ui:
		hotbar_ui.initialize_hotbar()
