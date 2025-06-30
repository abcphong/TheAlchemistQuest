extends CanvasLayer

var holding_item: Node = null
var inventory_node: Node2D
var is_dragging := false
@onready var dragging_layer = get_tree().get_current_scene().get_node("DraggingLayer")

func _ready():
	layer = 10  # Đặt cao hơn các UI khác
	add_to_group("UserInterface")

func update_held_item_visibility():
	if holding_item:
		holding_item.visible = true  # hoặc logic bạn mong muốn

func toggle_inventory():
	if inventory_node:
		inventory_node.visible = not inventory_node.visible
		
func _process(_delta):
	if is_dragging and holding_item:
		holding_item.global_position = get_viewport().get_mouse_position()

func is_mouse_over_slot() -> bool:
	var mouse_pos = get_viewport().get_mouse_position()
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.get_global_rect().has_point(mouse_pos):
			return true
	return false

func drop_item_to_world(item):
	print("💥 Vứt item ra ngoài: ", item.item_name)
	item.queue_free()

func get_slot_under_mouse() -> InventorySlot:
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
	return null
	
func return_item_to_inventory(item: Control) -> bool:
	# 1. Tìm slot trống trong Hotbar trước
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_hotbar_slot and slot.item == null:
			if item.get_parent():
				item.get_parent().remove_child(item)
			slot.initialize_item(item.item_name, item.item_quantity)
			item.queue_free()
			print("✅ Trả item về HOTBAR slot:", slot.slot_index, "| Item:", item.item_name)
			return true

	# 2. Nếu Hotbar đầy, tìm slot trống trong Inventory (theo slot_index tăng dần)
	var inventory_slots := get_tree().get_nodes_in_group("InventorySlot")
	inventory_slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)
	for slot in inventory_slots:  # ✅ Lặp qua danh sách đã sort
		if not slot.is_hotbar_slot and slot.item == null:
			if item.get_parent():
				item.get_parent().remove_child(item)
			slot.initialize_item(item.item_name, item.item_quantity)
			item.queue_free()
			print("✅ Trả item về INVENTORY slot:", slot.slot_index, "| Item:", item.item_name)
			return true

	# 3. Cảnh báo nếu không còn chỗ
	print("❌ Không thể trả item về inventory hoặc hotbar: ", item.item_name)
	return false

func add_new_item_to_inventory(item_name: String, quantity: int) -> bool:
	print("🧪 add_new_item_to_inventory được gọi với:", item_name, "x", quantity)

	var item_scene = load("res://The_Alchemist_Quest/scences/player/item.tscn")
	if item_scene == null:
		print("❌ Không thể load scene item.tscn")
		return false

	var item_instance = item_scene.instantiate()
	item_instance.set_item(item_name, quantity)

	var inventory_slots := get_tree().get_nodes_in_group("InventorySlot")
	inventory_slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)

	for slot in inventory_slots:
		if slot.is_hotbar_slot and slot.item == null:
			print("🎯 Gán vào HOTBAR slot:", slot.slot_index)
			slot.initialize_item(item_name, quantity)
			return true

	for slot in inventory_slots:
		if not slot.is_hotbar_slot and slot.item == null:
			print("🎯 Gán vào INVENTORY slot:", slot.slot_index)
			slot.initialize_item(item_name, quantity)
			return true

	print("❌ Inventory đầy, không thể thêm:", item_name)
	return false
