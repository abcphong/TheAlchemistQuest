extends CanvasLayer

var holding_item = null
var held_item_slot_index: int = -1
var held_item_is_hotbar: bool = false

func _input(event):
	if event.is_action_pressed("open_inventory"):
		$Inventory.visible = !$Inventory.visible
		if $Inventory.visible:
			$Inventory.initialize_inventory()
	
	if holding_item:
		holding_item.global_position = get_viewport().get_mouse_position()

func update_held_item_visibility():
	if holding_item:
		holding_item.visible = true
		move_child(holding_item, get_child_count() - 1)
