extends Node2D

class_name InventoryItem

@onready var icon = $TextureRect
var item_name: String = ""
var item_quantity: int = 0

func _ready():
	
	var rand_val = randi() % 5
	if rand_val == 0:
		item_name = "Activated_coal"
	elif rand_val == 1:
		item_name = "Filter_cotton"
	elif rand_val == 2:
		item_name = "Gas_mask"
	elif rand_val == 3:
		item_name = "Improved_mask"
	else:
		item_name = "Mini_oxygen"
		
	var texture_node = get_node_or_null("TextureRect")
	if texture_node:
		texture_node.texture = load("res://The_Alchemist_Quest/assets/gameDemo/" + item_name + ".png")
		
	var stack_size = int(JsonData.item_data.get(item_name, {}).get("StackSize", 1))
	item_quantity = randi() % stack_size + 1

	var label = get_node_or_null("Label")
	if label:
		label.visible = stack_size > 1
		if label.visible:
			label.text = str(item_quantity)

func _update_visual():
	var texture_node = get_node_or_null("TextureRect")
	if not texture_node:
		print("⚠️ TextureRect not found in this slot")
		return

	var path = "res://The_Alchemist_Quest/assets/gameDemo/" + item_name + ".png"
	print("Texture path:", path)
	
	if ResourceLoader.exists(path):
		texture_node.texture = load(path)
	else:
		print("❌ Texture not found:", path)

func set_item(nm, qt):
	item_name = nm
	item_quantity = qt
	update_icon()
	
	var label = get_node_or_null("Label")
	var texture_node = get_node_or_null("TextureRect")
	if label:
		label.text = str(qt)
	if texture_node:
		texture_node.texture = load("res://The_Alchemist_Quest/assets/gameDemo/" + item_name + ".png")
	
	var stack_size = int(JsonData.item_data.get(item_name, {}).get("StackSize", 1))
	if label:
		label.visible = stack_size > 1
		if label.visible:
			label.text = str(item_quantity)
	print("Setting item:", item_name, "Quantity:", qt)
	print("Texture path:", "res://The_Alchemist_Quest/assets/gameDemo/" + item_name + ".png")
	_update_visual()

func update_icon():
	var icon_path = "res://The_Alchemist_Quest/assets/gameDemo/%s.png" % item_name
	print("Texture path:", icon_path)

	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		icon.texture = null
		print("⚠️ Icon not found for:", item_name)

func add_item_quantity(amount_to_add):
	item_quantity += amount_to_add
	var label = get_node_or_null("Label")
	if label:
		label.text = str(item_quantity)

func decrease_item_quantity(amount_to_remove):
	item_quantity -= amount_to_remove
	var label = get_node_or_null("Label")
	if label:
		label.text = str(item_quantity)

func try_add_quantity(amount):
	var stack_size = int(JsonData.item_data[item_name].get("StackSize", 1))
	if item_quantity + amount <= stack_size:
		item_quantity += amount
		var label = get_node_or_null("Label")
		if label:
			label.text = str(item_quantity)
		return true
	return false

signal item_right_clicked(item_name: String, item_description: String)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("item_right_clicked", item_name, JsonData.item_data[item_name]["Description"])
