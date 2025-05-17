extends Node2D

@onready var hotbar = $HotbarSlot
@onready var slots = hotbar.get_children()
const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/slot.gd")

func _ready():
	for i in range(slots.size()):
		if slots[i] is InventorySlot:
			slots[i].slot_index = i 
			slots[i].gui_input.connect(slot_gui_input.bind(slots[i]))
	initialize_hotbar()
	
func initialize_hotbar():
	for i in range(slots.size()):
		if PlayerInventory.hotbar.has(i):
			slots[i].initialize_item(PlayerInventory.hotbar[i][0],PlayerInventory.hotbar[i][1])

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				handle_left_click(event, slot)
				

func handle_left_click(event: InputEvent, slot: InventorySlot):
	var ui = get_tree().root.find_child("UserInterface", true, false)
	if ui == null:
		return
	# Currently holding an Item
	if ui.holding_item != null:
		handle_place_item(ui,slot,event)
	else:
		handle_pick_item(ui,slot)
		
func handle_place_item(ui,slot: InventorySlot, event: InputEvent):
		# Empty slot
		if !slot.item:
			if slot.putIntoSlot(ui.holding_item):
				ui.holding_item = null
		# Slot already contains an item
		else:
			# Different item, so swap 
			if ui.holding_item.item_name != slot.item.item_name:
				var temp_item = slot.pickFromSlot()
				if temp_item:
					temp_item.global_position = event.global_postion
					ui.add_child(temp_item)
					if slot.putIntoSlot(ui.holding_item):
						ui.holding_item = temp_item
			# Same item, try to merge
			else:
				var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
				var able_to_add = stack_size - slot.item.item_quantity
				if able_to_add >= ui.holding_item.item_quantity:
					slot.item.add_item_quantity(ui.holding_item.item_quantity)
					ui.holding_item.queue_free()
					ui.holding_item = null
				else:
					slot.item.add_item_quantity(able_to_add)
					ui.holding_item.decrease_item_quantity(able_to_add)

func handle_pick_item(ui,slot:InventorySlot):
	if slot.item:
		ui.holding_item = slot.pickFromSlot()
		if ui.holding_item:
			ui.add_child(ui.holding_item)
			ui.holding_item.global_position = get_global_mouse_position()
