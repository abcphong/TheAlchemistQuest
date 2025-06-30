extends Panel

class_name InventorySlot 

var ItemClass = preload("res://The_Alchemist_Quest/scences/player/item.tscn")
var item: Control = null
var item_data = {}
var slot_index = -1 
var is_hotbar_slot := false
var is_puzzle_ui := false  # ✅ Thêm biến để kiểm tra trạng thái puzzle UI

@onready var popup_panel = get_node("../../PopupPanel")
@onready var popup_label = get_node("../../PopupPanel/VBoxContainer/DescriptionLabel")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	gui_input.connect(_on_gui_input)
	add_to_group("InventorySlot")
	check_puzzle_ui_status()  # ✅ Kiểm tra trạng thái puzzle UI

# ✅ Thêm hàm kiểm tra puzzle UI status (tương tự như panel_description.gd)
func check_puzzle_ui_status():
	# Kiểm tra PuzzleUI hoặc puzzle_ui_task1 trong scene
	var puzzle_ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
	if puzzle_ui == null:
		puzzle_ui = get_tree().get_current_scene().find_child("puzzle_ui_task1", true, false)
	
	# Kiểm tra xem puzzle UI có visible và đang hoạt động không
	if puzzle_ui != null and puzzle_ui.visible:
		is_puzzle_ui = true
		#print_debug("✅ InventorySlot - Puzzle UI detected and active")
	else:
		is_puzzle_ui = false

func initialize_item(item_name: String, item_quantity: int):
	print("⏳ Init Slot:", slot_index, "| Hotbar:", is_hotbar_slot, "| Name:", item_name, "| Qty:", item_quantity)
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
		item.item_right_clicked.connect(_on_item_right_clicked)
		
		update_inventory_dict()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		# ✅ Cập nhật trạng thái puzzle UI mỗi khi có input
		check_puzzle_ui_status()
		
		print("Click | Button:", 
			 "RIGHT" if event.button_index == MOUSE_BUTTON_RIGHT else "LEFT",
			 " | Item:", item.item_name if item else "None",
			 " | Children:", get_children(),
			 " | is_puzzle_ui:", is_puzzle_ui)  # ✅ Thêm log để debug
		
		if event.button_index == MOUSE_BUTTON_RIGHT and item:
			show_item_description()
			get_viewport().set_input_as_handled()

func show_item_description():
	if !item or !is_instance_valid(item):
		return
	
	# ✅ Kiểm tra trạng thái puzzle UI trước khi hiển thị popup
	check_puzzle_ui_status()
	if is_puzzle_ui:
		return
	
	var description = JsonData.get_item_description(item.item_name)
	_show_popup(item.item_name, description)

func _on_item_right_clicked(item_name: String, description: String):
	# ✅ Kiểm tra trạng thái puzzle UI trước khi hiển thị popup
	check_puzzle_ui_status()
	if is_puzzle_ui:
		return
	
	_show_popup(item_name, description)

func _show_popup(item_name: String, description: String):
	# ✅ Double check puzzle UI status
	if is_puzzle_ui:
		return
		
	popup_label.text = description
	#popup_panel.global_position = get_global_mouse_position() + Vector2(20, 20)
	#popup_panel.z_index = 1000
	popup_panel.show()

func update_inventory_dict():
	if slot_index == -1:
		return
	var target_dict = PlayerInventory.hotbar if is_hotbar_slot else PlayerInventory.inventory
	if item:
		target_dict[slot_index] = [item.item_name, item.item_quantity]
		print("📥 Ghi vào dict:", slot_index, "->", item.item_name, " | target_dict:", target_dict)
	else:
		target_dict[slot_index] = null
		print("📥 Xóa slot:", slot_index, " -> null")

func pickFromSlot() -> Control :
	if item == null:
		return null
		
	var picked_item = item
	remove_child(item)
	item = null
	update_inventory_dict()
	
	return picked_item

func putIntoSlot(new_item: Control) -> bool:
	if new_item == null:
		return false

	# Remove from current parent
	var old_parent = new_item.get_parent()
	if old_parent and old_parent != self:
		old_parent.remove_child(new_item)

	# Remove old item (if any)
	if item:
		remove_child(item)
		item.queue_free()

	# Set and add new item
	item = new_item
	add_child(item)
	item.position = Vector2(0, 0)
	item.visible = true                     # ✅ Bảo đảm nó hiện
	item.set_z_as_relative(false)
	item.z_index = 10                        # ✅ Đảm bảo nó render trên UI
	item.name = "InventoryItem"
	item.item_right_clicked.connect(_on_item_right_clicked)
	print("🧪 putIntoSlot:", slot_index, "->", item.item_name, "| parent:", item.get_parent().name)
	update_inventory_dict()
	if is_hotbar_slot:
		var hotbar_ui = get_tree().root.find_child("Hotbar", true, false)
		if hotbar_ui:
			hotbar_ui.initialize_hotbar()
	return true


func is_mouse_over() -> bool:
	return get_slot_rect().has_point(get_viewport().get_mouse_position())

func get_slot_rect() -> Rect2:
	return Rect2(global_position, size)
