extends InteractableBase

@export var puzzle_ui_scene: PackedScene = null  # Scene for the puzzle UI

var message_timer = 0.0
var message_interval = 3.0  # Show message every 3 seconds

func _ready():
	# Set default values for electrical cabinet
	item_name = "Copper wire"
	item_quantity = 1
	interaction_group = "computer"
	
	# Call parent _ready
	super._ready()

func _on_ready():
	# Custom initialization for electrical cabinet
	print("🔵 Electrical Cabinet initialized with item: ", item_name)

func _on_player_entered(body: Node2D):
	# Custom behavior when player enters cabinet area
	print("🔵 Cabinet: Player entered area")
	message_timer = 0.0  # Reset timer when player enters
	# Set the player's nearby_cabinet reference
	body.nearby_cabinet = self
	print("🔵 Cabinet: Set player's nearby_cabinet reference")

func _on_player_exited(body: Node2D):
	# Custom behavior when player exits cabinet area
	print("🔵 Cabinet: Player exited area")
	message_timer = 0.0  # Reset timer when player exits
	# Clear the player's nearby_cabinet reference
	if body.nearby_cabinet == self:
		body.nearby_cabinet = null
		print("🔵 Cabinet: Cleared player's nearby_cabinet reference")

func _on_item_given():
	# Custom behavior after giving item
	print("🔵 Cabinet: Copper wire given successfully")
	# Open puzzle UI after giving item
	_open_puzzle_ui()

func _open_puzzle_ui():
	if puzzle_ui_scene:
		print("🔵 Cabinet: Opening puzzle UI")
		var puzzle_ui = puzzle_ui_scene.instantiate()
		get_tree().current_scene.add_child(puzzle_ui)
	else:
		print("⚠️ Cabinet: No puzzle UI scene assigned")

# Public method to open UI without giving item
func open_ui_only():
	"""Open puzzle UI without giving item (for external calls)"""
	_open_puzzle_ui()
