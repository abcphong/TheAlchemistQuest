extends Area2D
class_name InteractableBase

# Configuration for item pickup only
@export var item_name: String = ""
@export var item_quantity: int = 1
@export var can_give_multiple: bool = false  # If false, item can only be given once
@export var interaction_group: String = "interactable"  # Group to add this object to

# State
var player = null
var can_interact = false
var has_given_item = false

# Signals
signal item_given(item_name: String, item_quantity: int)
signal interaction_started
signal interaction_ended

func _ready():
	add_to_group(interaction_group)
	
	# Set up collision detection
	collision_layer = 2  # Layer 2 for interactable objects
	collision_mask = 1   # Mask 1 for player
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Call virtual method for custom initialization
	_on_ready()

func _process(_delta):
	if can_interact and Input.is_action_just_pressed("interaction"):
		_handle_interaction()

func _handle_interaction():
	print("🔵 Item pickup triggered with: ", name)
	
	# Check if we can give item
	if _can_give_item():
		if _give_item():
			_on_item_given()
		else:
			print("❌ Failed to give item - Inventory might be full")
	else:
		print("❌ Cannot give item - Already given or conditions not met")

func _can_give_item() -> bool:
	# Override this method in derived classes for custom logic
	return not has_given_item or can_give_multiple

func _give_item() -> bool:
	if item_name.is_empty():
		print("⚠️ No item configured for: ", name)
		return false
	
	print("🔵 Attempting to give item: ", item_name, " x", item_quantity)
	if PlayerInventory.add_item(item_name, item_quantity):
		print("✅ Successfully gave item: ", item_name)
		has_given_item = true
		item_given.emit(item_name, item_quantity)
		return true
	else:
		print("❌ Failed to give item: ", item_name)
		return false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("🔵 Player entered pickup area: ", name)
		can_interact = true
		player = body
		interaction_started.emit()
		_on_player_entered(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("🔵 Player exited pickup area: ", name)
		can_interact = false
		player = null
		interaction_ended.emit()
		_on_player_exited(body)

# Virtual methods that can be overridden in derived classes
func _on_ready():
	# Override this method for custom initialization
	pass

func _on_player_entered(body: Node2D):
	# Override this method for custom behavior when player enters
	pass

func _on_player_exited(body: Node2D):
	# Override this method for custom behavior when player exits
	pass

func _on_item_given():
	# Override this method for custom behavior after item is given
	pass

# Public methods
func reset_item_state():
	"""Reset the item giving state (useful for testing or respawning)"""
	has_given_item = false
	print("🔄 Reset item state for: ", name)

func set_item(new_item_name: String, new_item_quantity: int = 1):
	"""Change the item that this interactable gives"""
	item_name = new_item_name
	item_quantity = new_item_quantity
	print("📦 Updated item for ", name, ": ", item_name, " x", item_quantity)

func get_item_info() -> Dictionary:
	"""Get information about the item this interactable gives"""
	return {
		"item_name": item_name,
		"item_quantity": item_quantity,
		"has_given": has_given_item,
		"can_give_multiple": can_give_multiple
	} 
