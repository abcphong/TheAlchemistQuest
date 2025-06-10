# 📄 inventory.gd
extends Node2D

# signal inventory_updated  # Removed unused signal

const SlotClass = preload("res://The_Alchemist_Quest/scripts/inventory/slot.gd")
@onready var inventory_slots = $GridContainer
@onready var popup_panel = $PopupPanel
@onready var popup_label = $PopupPanel/VBoxContainer/DescriptionLabel

var is_dragging := false
var is_initialized := false
var is_updating := false  # Prevent recursive updates
var is_puzzle_interaction := false  # Flag for puzzle slot interactions

func _ready():
	if not is_initialized:
		for i in range(inventory_slots.get_child_count()):
			var inv_slot = inventory_slots.get_child(i)
			inv_slot.slot_index = i
			inv_slot.gui_input.connect(slot_gui_input.bind(inv_slot))
			inv_slot.add_to_group("InventorySlot")
		is_initialized = true
	initialize_inventory()
	popup_panel.hide()
	# Connect to PlayerInventory's inventory_updated signal
	if PlayerInventory.has_signal("inventory_updated"):
		PlayerInventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))

func _on_inventory_updated():
	if not is_updating:
		initialize_inventory()

func initialize_inventory():
	if is_updating:
		return
		
	is_updating = true
	print("🔵 Initializing inventory")
	print("PlayerInventory content: ", PlayerInventory.inventory)
	var slots = $GridContainer.get_children()
	for i in range(slots.size()):
		if PlayerInventory.inventory.has(i):
			var slot_data = PlayerInventory.inventory[i]
			if slot_data != null and slot_data[0] != null:
				var item_name = str(slot_data[0])
				var item_quantity = int(slot_data[1])
				slots[i].initialize_item(item_name, item_quantity)
			else:
				slots[i].initialize_item("", 0)
		else:
			slots[i].initialize_item("", 0)
	is_updating = false
	emit_signal("inventory_updated")

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if UserInterface.holding_item == null and slot.item:
				UserInterface.holding_item = slot.pickFromSlot()
				var ui = get_tree().get_current_scene().find_child("PuzzleUI", true, false)
				if ui:
					ui.add_child(UserInterface.holding_item)
				else:
					UserInterface.add_child(UserInterface.holding_item) # fallback
				UserInterface.holding_item.set_z_as_relative(false)
				UserInterface.holding_item.z_index = 9999
				UserInterface.holding_item.global_position = get_viewport().get_mouse_position()
				
				print_debug("📦 Item Parent:", UserInterface.holding_item.get_parent().name)

				var puzzle_node := get_tree().get_current_scene().find_child("PuzzleUI", true, false)
				if puzzle_node:
					print_debug("🧩 PuzzleUI Parent:", puzzle_node.get_parent().name)
				else:
					print_debug("❗ PuzzleUI not found in scene tree.")
					
				UserInterface.update_held_item_visibility()
				UserInterface.is_dragging = true
				# 🐞 Thêm debug tại đây:
				print("🧪 InventoryUI layer:", UserInterface.layer)
				
				if puzzle_node:
					print("🧪 PuzzleUI layer:", puzzle_node.layer)
		else:
			if UserInterface.holding_item:
				UserInterface.is_dragging = false
				var hovered_slot = get_slot_under_mouse()
				try_drop_item(hovered_slot, event.global_position)
	elif event is InputEventMouseMotion and is_dragging:
		if UserInterface.holding_item:
			UserInterface.holding_item.global_position = event.global_position

func get_slot_under_mouse() -> SlotClass:
	for slot in get_tree().get_nodes_in_group("InventorySlot"):
		if slot.is_mouse_over():
			return slot
	return null
	
func try_drop_item(slot: Node, mouse_pos: Vector2):
	if slot == null:
		print("⚠ Không tìm thấy slot dưới chuột, kiểm tra PuzzleSlot...")

		# Kiểm tra PuzzleSlot trước
		for puzzle_slot in get_tree().get_nodes_in_group("PuzzleSlot"):
			if not puzzle_slot is Control:
				continue  # Bỏ qua nếu không phải node UI Control

			var rect := Rect2(puzzle_slot.global_position, puzzle_slot.size)
			if rect.has_point(mouse_pos):
				print("✅ Thả vào PuzzleSlot:", puzzle_slot.name)
				is_puzzle_interaction = true
				puzzle_slot.receive_item(UserInterface.holding_item)
				UserInterface.holding_item = null
				is_puzzle_interaction = false
				if not is_updating:
					initialize_inventory()
				return

		# Nếu không phải PuzzleSlot thì vứt ra ngoài
		drop_item_to_world(UserInterface.holding_item)
		UserInterface.holding_item = null
		if not is_updating:
			initialize_inventory()
		return

	# Nếu là InventorySlot thì xử lý như cũ
	var is_inside = slot.get_global_rect().has_point(mouse_pos)
	if is_inside:
		if !slot.item:
			left_click_empty_slot(slot)
		elif slot.item.item_name == UserInterface.holding_item.item_name:
			left_click_same_item(slot)
		else:
			left_click_different_item(null, slot)
	else:
		drop_item_to_world(UserInterface.holding_item)
		UserInterface.holding_item = null
	if not is_updating:
		initialize_inventory()

func drop_item_to_world(item):
	print("💥 Dropping item into world: ", item.item_name)
	
	# Get the current scene
	var current_scene = get_tree().get_current_scene()
	print("Current scene: ", current_scene.name)
	
	# Create dropped item instance
	var dropped_item_scene = load("res://The_Alchemist_Quest/scences/player/dropped_item.tscn")
	var dropped_item = dropped_item_scene.instantiate()
	print("Created dropped item instance")
	
	# Get player position for drop location
	var player = get_tree().get_first_node_in_group("player")
	print("Found player: ", player != null)
	if player:
		print("Player position: ", player.global_position)
		print("Player collision layer: ", player.collision_layer, " Player collision mask: ", player.collision_mask)
		dropped_item.global_position = player.global_position
		current_scene.add_child(dropped_item)
		dropped_item.initialize(item.item_name, item.item_quantity)
		print("Added dropped item to scene")
		print("Dropped item collision layer: ", dropped_item.get_node("Area2D").collision_layer, " Dropped item collision mask: ", dropped_item.get_node("Area2D").collision_mask)
	else:
		print("❌ Player not found in 'player' group!")
	
	# Remove item from inventory
	item.queue_free()
	if not is_updating:
		initialize_inventory()

func handle_right_click(_event: InputEvent, slot: SlotClass):
	if slot.item:
		popup_label.text = JsonData.get_item_description(slot.item.item_name)
		popup_panel.global_position = get_global_mouse_position() + Vector2(20, 20)
		popup_panel.show()
		slot.modulate = Color(1, 0.8, 0)
		await get_tree().create_timer(0.1).timeout
		slot.modulate = Color(1, 1, 1)

func show_description_popup(description: String, popup_position: Vector2):
	popup_label.text = description
	popup_panel.global_position = popup_position + Vector2(20, 20)
	popup_panel.show()

func _input(event):
	if UserInterface.holding_item:
		UserInterface.holding_item.global_position = get_global_mouse_position()

	if event is InputEventMouseButton and event.pressed and popup_panel.visible:
		if not popup_panel.get_global_rect().has_point(event.global_position):
			popup_panel.hide()

func left_click_empty_slot(slot: SlotClass):
	slot.putIntoSlot(UserInterface.holding_item)
	PlayerInventory.add_item_to_empty_slot(UserInterface.holding_item, slot)
	UserInterface.holding_item = null
	if not is_updating:
		initialize_inventory()

func left_click_different_item(event: InputEvent, slot: SlotClass):
	PlayerInventory.remove_item(slot)
	var temp_item = slot.pickFromSlot()
	if event:
		temp_item.global_position = event.get_global_position()

	if slot.putIntoSlot(UserInterface.holding_item):
		PlayerInventory.add_item_to_empty_slot(UserInterface.holding_item, slot)
		UserInterface.holding_item = temp_item
		UserInterface.add_child(UserInterface.holding_item)
		UserInterface.holding_item.global_position = get_global_mouse_position()
		UserInterface.update_held_item_visibility()
	if not is_updating:
		initialize_inventory()

func left_click_same_item(slot: SlotClass):
	var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
	var able_to_add = stack_size - slot.item.item_quantity
	if able_to_add >= UserInterface.holding_item.item_quantity:
		PlayerInventory.add_item_quantity(slot, UserInterface.holding_item.item_quantity)
		slot.item.add_item_quantity(UserInterface.holding_item.item_quantity)
		UserInterface.holding_item.queue_free()
		UserInterface.holding_item = null
		if not is_updating:
			initialize_inventory()
	else:
		PlayerInventory.add_item_quantity(slot, able_to_add)
		slot.item.add_item_quantity(able_to_add)
		UserInterface.holding_item.decrease_item_quantity(able_to_add)
	if not is_updating:
		initialize_inventory()
