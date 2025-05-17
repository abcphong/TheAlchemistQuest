extends Node2D

const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/slot.gd")
@onready var inventory_slots = $GridContainer

@onready var popup_panel = $PopupPanel
@onready var popup_label = $PopupPanel/VBoxContainer/DescriptionLabel


func _ready():
	for inv_slot in inventory_slots.get_children():
		inv_slot.gui_input.connect(slot_gui_input.bind(inv_slot))
	initialize_inventory()
	
	popup_panel.hide()

		
func initialize_inventory():
	print("PlayerInventory content: ", PlayerInventory.inventory)
	var slots = $GridContainer.get_children()
	for i in range(slots.size()):
		if PlayerInventory.inventory.has(i) && PlayerInventory.inventory[i] != null:
			var item_name = str(PlayerInventory.inventory[i][0]) if PlayerInventory.inventory[i][0] != null else ""
			var item_quantity = int(PlayerInventory.inventory[i][1]) if PlayerInventory.inventory[i][1] != null else 0
			slots[i].initialize_item(item_name, item_quantity)
		else:
			slots[i].initialize_item("", 0)  

		
func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				handle_left_click(event, slot)
			MOUSE_BUTTON_RIGHT:
				handle_right_click(event, slot)
				get_viewport().set_input_as_handled()

func handle_left_click(event: InputEvent, slot: SlotClass):
	# Currently holding an Item
	if find_parent("UserInterface").holding_item != null:
		# Empty slot
		if !slot.item:
			slot.putIntoSlot(find_parent("UserInterface").holding_item)
			find_parent("UserInterface").holding_item = null
		# Slot already contains an item
		else:
			# Different item, so swap 
			if find_parent("UserInterface").holding_item.item_name != slot.item.item_name:
				var temp_item = slot.item
				slot.pickFromSlot()
				temp_item.global_position = event.global_position
				slot.putIntoSlot(find_parent("UserInterface").holding_item)
				find_parent("UserInterface").holding_item = temp_item
			# Same item, try to merge
			else:
				var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
				var able_to_add = stack_size - slot.item.item_quantity
				if able_to_add >= find_parent("UserInterface").holding_item.item_quantity:
					slot.item.add_item_quantity(find_parent("UserInterface").holding_item.item_quantity)
					find_parent("UserInterface").holding_item.queue_free()
					find_parent("UserInterface").holding_item = null	
				else:
					slot.item.add_item_quantity(able_to_add)
					find_parent("UserInterface").holding_item.decrease_item_quantity(able_to_add)
	# Not holding an item
	elif slot.item:
		find_parent("UserInterface").holding_item = slot.item
		slot.pickFromSlot()
		find_parent("UserInterface").holding_item.global_position = get_global_mouse_position()


func handle_right_click(event:InputEvent, slot:SlotClass):
	if slot.item:
		var popup = $PopupPanel/VBoxContainer/DescriptionLabel
		popup.show_description({
			"name": slot.item.item_name,
			"image_path":"res://The_Alchemist_Quest/assets/gameDemo/%s.png" % slot.item.item_name,
			"description": JsonData.get_item_description(slot.item.item_name)
			},
			get_global_mouse_position()
			)
		slot.modulate = Color(1, 0.8, 0)  # Orange tint
		await get_tree().create_timer(0.1).timeout
		slot.modulate = Color(1, 1, 1)  # Back to normal


func show_description_popup(description: String, position: Vector2):
	popup_label.text = description
	
	
	popup_panel.global_position = position + Vector2(20, 20)  # Offset from mouse
	popup_panel.show()
	
func _input(event):
	if find_parent("UserInterface").holding_item:
		find_parent("UserInterface").holding_item.global_position = get_global_mouse_position()
		
	if event is InputEventMouseButton and event.pressed and popup_panel.visible:
		if not popup_panel.get_global_rect().has_point(event.global_position):
			popup_panel.hide()
			

	
