extends Node2D

var item_name: String = ""
var item_quantity: int = 0
var can_pickup: bool = false
const DROPPED_ITEM_SCALE = 0.5  # Adjust this value to control the size of dropped items
const PICKUP_RANGE = 100  # Distance at which player can pick up the item
var last_print_time: float = 0.0
const PRINT_COOLDOWN: float = 2.0  # Time in seconds between debug prints

func _ready():
	# Add to pickup group
	add_to_group("dropped_items")
	print("Dropped item initialized: ", item_name)
	
	# Connect area signals
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	
	# Enable debug visualization
	$Area2D/CollisionShape2D.debug_color = Color(1, 0, 0, 0.5)
	print("Collision layer: ", $Area2D.collision_layer, " Collision mask: ", $Area2D.collision_mask)

func initialize(item_name: String, quantity: int):
	self.item_name = item_name
	self.item_quantity = quantity
	print("Initializing dropped item: ", item_name, " with quantity: ", quantity)
	
	# Load and set the item texture
	var texture_path = "res://The_Alchemist_Quest/assets/puzzle/intro_room/" + item_name + ".png"
	$Sprite2D.texture = load(texture_path)
	
	# Set the scale
	$Sprite2D.scale = Vector2(DROPPED_ITEM_SCALE, DROPPED_ITEM_SCALE)
	
	# Set quantity label
	if item_quantity > 1:
		$Label.text = str(item_quantity)
	else:
		$Label.visible = false

func _process(_delta):
	# Check if player is near to enable pickup
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		can_pickup = distance < PICKUP_RANGE
		
		# Debug print for pickup state with cooldown
		var current_time = Time.get_ticks_msec() / 1000.0
		if can_pickup and (current_time - last_print_time) >= PRINT_COOLDOWN:
			print("Player in range of item: ", item_name, " (Distance: ", distance, ")")
			last_print_time = current_time
		
		# If player is in range and presses F, pick up the item
		if can_pickup and Input.is_action_just_pressed("pick_up"):
			print("Pick up key pressed for item: ", item_name)
			if PlayerInventory.add_item(item_name, item_quantity):
				print("Successfully picked up item: ", item_name)
				queue_free()  # Remove the dropped item if successfully picked up
			else:
				print("Failed to add item to inventory: ", item_name)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Mouse click detected")
		if can_pickup:
			print("Item can be picked up, attempting to add to inventory")
			# Try to add item to inventory
			if PlayerInventory.add_item(item_name, item_quantity):
				print("Successfully picked up item with mouse: ", item_name)
				queue_free()  # Remove the dropped item if successfully picked up
			else:
				print("Failed to add item to inventory with mouse: ", item_name)
		else:
			print("Item cannot be picked up (too far or not in range)")

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered item collision area: ", item_name)
		print("Player collision layer: ", body.collision_layer, " Player collision mask: ", body.collision_mask)
		can_pickup = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		print("Player exited item collision area: ", item_name)
		can_pickup = false 
