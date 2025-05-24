extends CanvasLayer

var holding_item: Node = null
var inventory_node: Node2D
var is_dragging := false
@onready var dragging_layer = get_tree().get_current_scene().get_node("DraggingLayer")

func _ready():
	layer = 10  # Đặt cao hơn các UI khác

func update_held_item_visibility():
	if holding_item:
		holding_item.visible = true  # hoặc logic bạn mong muốn

func toggle_inventory():
	if inventory_node:
		inventory_node.visible = not inventory_node.visible
		
func _process(_delta):
	if is_dragging and holding_item:
		holding_item.global_position = get_viewport().get_mouse_position()
		
#func drop_holding_item():
#	if holding_item:
#		var slot = get_slot_under_mouse()
#		if slot:
#			slot.putIntoSlot(holding_item)
#		else:
#			drop_item_to_world(holding_item)
#		
#		holding_item = null
#		is_dragging = false

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
