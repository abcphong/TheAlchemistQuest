extends InteractableBase
# Test script to demonstrate InteractableBase functionality

func _ready():
	# Test configuration
	item_name = "Test Item"
	item_quantity = 1
	interaction_group = "test_interactable"
	can_give_multiple = false
	
	# Call parent _ready
	super._ready()

func _on_ready():
	print("🧪 Test Interactable initialized")
	print("🧪 Item: ", item_name, " x", item_quantity)
	print("🧪 Group: ", interaction_group)

func _on_player_entered(body: Node2D):
	print("🧪 Test: Player entered interaction area")
	print("🧪 Player position: ", body.global_position)

func _on_player_exited(body: Node2D):
	print("🧪 Test: Player exited interaction area")

func _on_item_given():
	print("🧪 Test: Item given successfully!")
	print("🧪 Item info: ", get_item_info())

# Test method to demonstrate runtime configuration
func test_runtime_config():
	print("🧪 Testing runtime configuration...")
	
	# Change item
	set_item("New Test Item", 3)
	print("🧪 New item info: ", get_item_info())
	
	# Reset state
	reset_item_state()
	print("🧪 State reset, can give item again")
	
	# Test giving item again
	if _can_give_item():
		print("🧪 Can give item again after reset")
	else:
		print("🧪 Cannot give item after reset") 