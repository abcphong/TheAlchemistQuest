extends InteractableBase

@export var puzzle_ui_scene: PackedScene = null  # Scene for the puzzle UI

func _ready():
	# Set default values for computer
	item_name = "Zinc bar"
	item_quantity = 1
	interaction_group = "computer"
	
	# Call parent _ready
	super._ready()

func _on_ready():
	# Custom initialization for computer
	print("🔵 Computer initialized with item: ", item_name)

func _on_item_given():
	# Custom behavior after giving item
	print("🔵 Computer: Item given successfully")
	# Open puzzle UI after giving item
	_open_puzzle_ui()

func _open_puzzle_ui():
	if puzzle_ui_scene:
		print("🔵 Computer: Opening puzzle UI")
		var puzzle_ui = puzzle_ui_scene.instantiate()
		get_tree().current_scene.add_child(puzzle_ui)
	else:
		print("⚠️ Computer: No puzzle UI scene assigned")

# Public method to open UI without giving item
func open_ui_only():
	"""Open puzzle UI without giving item (for external calls)"""
	_open_puzzle_ui() 
