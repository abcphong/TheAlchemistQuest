extends Panel

class_name InventorySlot 

var ItemClass = preload("res://The_Alchemist_Quest/scences/player/item.tscn")
var item: Node2D = null
var item_data = {}
var slot_index = -1 

@onready var popup_panel = get_node("../../PopupPanel")
@onready var popup_label = get_node("../../PopupPanel/VBoxContainer/DescriptionLabel")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	gui_input.connect(_on_gui_input)

func initialize_item(item_name: String, item_quantity: int):
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
		print("Click | Button:", 
			 "RIGHT" if event.button_index == MOUSE_BUTTON_RIGHT else "LEFT",
			 " | Item:", item.item_name if item else "None",
			 " | Children:", get_children())
		
		if event.button_index == MOUSE_BUTTON_RIGHT and item:
			show_item_description()
			get_viewport().set_input_as_handled()

func show_item_description():
	if !item or !is_instance_valid(item):
		return
	
	var description = JsonData.get_item_description(item.item_name)
	_show_popup(item.item_name, description)

func _on_item_right_clicked(item_name: String, description: String):
	_show_popup(item_name, description)

func _show_popup(item_name: String, description: String):
	popup_label.text = description
	#popup_panel.global_position = get_global_mouse_position() + Vector2(20, 20)
	#popup_panel.z_index = 1000
	popup_panel.show()

func update_inventory_dict():
	if slot_index == -1:
		return
	
	if item:
		PlayerInventory.inventory[slot_index] = [item.item_name, item.item_quantity]
	else:
		PlayerInventory.inventory[slot_index] = null

func pickFromSlot():
	if item == null:
		return
		
	var picked_item = item
	remove_child(item)
	item = null
	update_inventory_dict()
	return picked_item

func putIntoSlot(new_item):
	if new_item == null:
		return false
		
	# Remove from current parent if exits
	var old_parent = new_item.get_parent()
	if old_parent and old_parent !=self:
		old_parent.remove_child(new_item)
		
	# Clear current item if exits
	if item:
		remove_child(item)
		item.queue.free()
		
	#Set new item
	item = new_item
	add_child(item)
	item.position = Vector2(0,0)
	update_inventory_dict()
	return true
