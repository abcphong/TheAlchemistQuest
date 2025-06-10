extends Panel
class_name PuzzleSlot
@export var expected_item: String = ""  # Tên item đúng để kiểm tra
var is_filled := false

func _ready():
	add_to_group("PuzzleSlot")

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var held_item = UserInterface.holding_item
		if held_item and not is_filled:
			if held_item.item_name == expected_item:
				print("✅ Đặt đúng item:", held_item.item_name)
				$ItemIcon.texture = held_item.get_node("TextureRect").texture
				is_filled = true
				held_item.queue_free()
				UserInterface.holding_item = null
				get_parent().check_all_slots_filled()
			else:
				print("❌ Sai item:", held_item.item_name, " | Cần:", expected_item)

func receive_item(item):
	if is_filled:
		return

	if item.item_name == expected_item:
		print("✅ Receiving correct item:", item.item_name)
		$ItemIcon.texture = item.get_node("TextureRect").texture
		is_filled = true
		
		# Add item to player's inventory without triggering recursive updates
		if PlayerInventory.add_item(item.item_name, item.item_quantity):
			print("✅ Added item to player inventory:", item.item_name)
		else:
			print("❌ Failed to add item to player inventory:", item.item_name)
		
		item.queue_free()
		UserInterface.holding_item = null
		get_parent().check_all_slots_filled()
	else:
		print("❌ Wrong item:", item.item_name, " | Expected:", expected_item)
