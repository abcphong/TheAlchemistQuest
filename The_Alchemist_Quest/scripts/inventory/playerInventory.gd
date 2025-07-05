extends Node

const NUM_INVENTORY_SLOTS = 9
const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/inventory_slot.gd")
const ItemClass = preload("res://The_Alchemist_Quest/scripts/inventory/item.gd")
const NUM_HOTBARS_SLOTS = 2

signal active_item_updated
signal inventory_changed

var inventory = {
	0: ["Copper wire", 1],
	1: ["CuSO4", 1],
	2: ["Electric wire" , 2],
	3: ["ZnSO4",1],
	4: ["Zinc bar",1],
	5: ["Salt bridge",1],
	6: [null,0],
	7: [null,0]
}

var hotbar = {
	0: ["",0],
	1: ["",0]
}

var active_item_slot = 0


func add_item(item_name, item_quantity):
	var quantity_to_add = item_quantity
	var item_definitions = JsonData.item_data.get("item", {})
	
	if not item_definitions.has(item_name):
		print("[PlayerInventory] CẢNH BÁO: Item ", item_name, " không tồn tại trong JsonData!")
		# Vẫn tiếp tục xử lý với stack_size mặc định
	
	var stack_size = int(item_definitions.get(item_name, {"StackSize": 1}).get("StackSize", 1))
	print("[PlayerInventory] Thêm item ", item_name, " x ", item_quantity, " (stack_size: ", stack_size, ")")
	
	# 1. Ưu tiên cộng dồn vào stack item cùng loại trong inventory
	for slot_index in inventory:
		if inventory[slot_index] != null and inventory[slot_index][0] == item_name:
			var current_quantity = inventory[slot_index][1]
			var available_space = stack_size - current_quantity
			
			if available_space > 0:
				var add_amount = min(available_space, quantity_to_add)
				inventory[slot_index][1] += add_amount
				quantity_to_add -= add_amount
				print("[PlayerInventory] Đã cộng dồn ", add_amount, " ", item_name, " vào inventory slot ", slot_index)
				
				if quantity_to_add <= 0:
					inventory_changed.emit()
					return true
	
	# 2. Thêm vào slot trống trong inventory
	if quantity_to_add > 0:
		for slot_index in inventory:
			if inventory[slot_index] == null or inventory[slot_index][0] == null:
				var add_amount = min(stack_size, quantity_to_add)
				inventory[slot_index] = [item_name, add_amount]
				quantity_to_add -= add_amount
				print("[PlayerInventory] Đã thêm ", add_amount, " ", item_name, " vào inventory slot trống ", slot_index)
				
				if quantity_to_add <= 0:
					inventory_changed.emit()
					return true
	
	# 3. Cộng dồn vào stack item cùng loại trong hotbar
	if quantity_to_add > 0:
		for slot_index in hotbar:
			if hotbar[slot_index] != null and hotbar[slot_index][0] == item_name:
				var current_quantity = hotbar[slot_index][1]
				var available_space = stack_size - current_quantity
				
				if available_space > 0:
					var add_amount = min(available_space, quantity_to_add)
					hotbar[slot_index][1] += add_amount
					quantity_to_add -= add_amount
					print("[PlayerInventory] Đã cộng dồn ", add_amount, " ", item_name, " vào hotbar slot ", slot_index)
					
					if quantity_to_add <= 0:
						inventory_changed.emit()
						return true
	
	# 4. Thêm vào slot trống trong hotbar
	if quantity_to_add > 0:
		for slot_index in hotbar:
			if hotbar[slot_index] == null or hotbar[slot_index][0] == "" or hotbar[slot_index][0] == null:
				var add_amount = min(stack_size, quantity_to_add)
				hotbar[slot_index] = [item_name, add_amount]
				quantity_to_add -= add_amount
				print("[PlayerInventory] Đã thêm ", add_amount, " ", item_name, " vào hotbar slot trống ", slot_index)
				
				if quantity_to_add <= 0:
					inventory_changed.emit()
					return true

	# Nếu vẫn còn item_quantity > 0, có nghĩa là không đủ chỗ trong cả inventory và hotbar
	if quantity_to_add < item_quantity:
		inventory_changed.emit()
		
	if quantity_to_add > 0:
		print("[PlayerInventory] Không đủ chỗ để thêm ", quantity_to_add, " ", item_name, " còn lại!")
		return false
		
	return true
	
func remove_item(slot_index: int, is_hotbar: bool):
	var target_dict = hotbar if is_hotbar else inventory
	if target_dict.has(slot_index):
		if is_hotbar:
			target_dict[slot_index] = ["", 0]
		else:
			target_dict[slot_index] = [null, 0]
	inventory_changed.emit()

func update_item_quantity(slot_index: int, new_quantity: int, is_hotbar: bool):
	var target_dict = hotbar if is_hotbar else inventory
	if target_dict.has(slot_index) and target_dict[slot_index] != null:
		target_dict[slot_index][1] = new_quantity
		if new_quantity <= 0:
			remove_item(slot_index, is_hotbar)
	inventory_changed.emit()

func add_item_to_empty_slot(item: ItemClass, slot: SlotClass, is_hotbar: bool = false):
	if is_hotbar or slot.is_hotbar_slot:
		hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
	else:
		inventory[slot.slot_index] = [item.item_name, item.item_quantity]
	inventory_changed.emit()

	
func add_item_quantity(slot: SlotClass, quantity_to_add: int, is_hotbar: bool = false):
	if is_hotbar or slot.is_hotbar_slot:
		if slot.slot_index >= 0 and hotbar.has(slot.slot_index) and hotbar[slot.slot_index] != null:
			hotbar[slot.slot_index][1] += quantity_to_add
	else:
		if slot.slot_index >= 0 and inventory.has(slot.slot_index) and inventory[slot.slot_index] != null:
			inventory[slot.slot_index][1] += quantity_to_add
	inventory_changed.emit()
	
