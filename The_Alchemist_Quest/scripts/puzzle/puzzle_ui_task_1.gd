extends CanvasLayer

@onready var success_anim = $SuccessAnim  # Optional: add a success animation node if you want
@onready var inventory = $InventoryContainer/Inventory

func _ready():
	print("🔵 Puzzle UI Task 1 initializing")
	if has_node("SuccessAnim"):
		success_anim.visible = false
	add_to_group("PuzzleSlot")
	
	# Ensure inventory is properly initialized
	if inventory:
		print("✅ Initializing puzzle inventory")
		inventory.initialize_inventory()
		
		# Connect to inventory update signal
		inventory.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
	else:
		print("❌ No inventory node found")

func _on_inventory_updated():
	print("🔵 Inventory updated, refreshing display")
	if inventory and not inventory.is_updating:
		inventory.initialize_inventory()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("🔵 Closing puzzle UI")
		queue_free()

func check_all_slots_filled():
	for child in get_children():
		if child is PuzzleSlot and not child.is_filled:
			return
	if has_node("SuccessAnim"):
		success_anim.visible = true
		success_anim.play("complete")
