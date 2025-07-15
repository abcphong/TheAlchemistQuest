extends InteractableBase
# Example script showing how to use the InteractableBase class for item pickup only

func _ready():
	# Example: Simple item pickup (gives item once)
	item_name = "FeSO4"
	item_quantity = 2
	interaction_group = "item_giver"
	
	# Call parent _ready
	super._ready()

func _on_ready():
	print("🔵 Item Giver Example initialized")

func _on_item_given():
	print("🔵 Example: FeSO4 picked up successfully")
	# Add custom effects here (sound, particles, etc.) 