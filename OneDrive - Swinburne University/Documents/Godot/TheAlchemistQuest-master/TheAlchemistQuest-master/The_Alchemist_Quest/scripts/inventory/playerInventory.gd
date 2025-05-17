extends Node

const NUM_INVENTORY_SLOTS = 9
const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/slot.gd")
const ItemClass = preload("res://The_Alchemist_Quest/scripts/inventory/item.gd")
const NUM_HOTBARS_SLOTS = 2

signal active_item_updated

var inventory = {
	0: ["H₂ Gas Cylinder" , 2],
	1: ["O₂ Gas Cylinder", 1],
	2: ["Bật lửa" , 1],
	3: ["Giấy Note", 1],
	4: [null,0],
	5: [null,0],
	6: [null,0],
	7: [null,0],
	8: [null,0]
}

var hotbar = {
	0: ["",0],
	1: ["",0]
}

var active_item_slot = 0


func add_item(item_name, item_quantity):
	var stack_size = int(JsonData.item_data[item_name].get("StackSize",1))
	
	# Stack with existing items
	for slot_index in inventory:
		var slot = inventory[slot_index]
		if slot != null && slot[0] == item_name:
			var available_slot = stack_size - slot[1]
			if available_slot > 0:
				var add_amount = min(available_slot, item_quantity)
				slot[1] += add_amount
				item_quantity -=add_amount
				if item_quantity == 0:
					return true
		
	pass
	#item does not exist in inventory yet, so add it to an empty slot
	if item_quantity > 0:
		for slot_index in range(NUM_INVENTORY_SLOTS):
			if inventory[slot_index] == null:
				var add_amount = min(stack_size, item_quantity)
				inventory[slot_index] = [item_name,add_amount]
				item_quantity -= add_amount
				if item_quantity == 0:
					return true
					
	return false
	
func remove_item(slot: SlotClass,is_hotbar: bool = false):
	if is_hotbar:
		hotbar.erase(slot.slot_index)
	else:
		inventory.erase(slot.slot_index)
	
func add_item_to_empty_slot(item: ItemClass, slot: SlotClass,is_hotbar: bool = false):
	if is_hotbar:
		hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
	else:
		inventory[slot.slot_index] = [item.item_name, item.item_quantity]
	
func add_item_quantity(slot: SlotClass, quantity_to_add: int, is_hotbar: bool = false):
	if is_hotbar:
		hotbar[slot.slot_index][1] += quantity_to_add
	else:
		inventory[slot.slot_index][1] += quantity_to_add
	

	
