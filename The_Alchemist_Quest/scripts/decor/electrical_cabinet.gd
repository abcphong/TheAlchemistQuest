extends Area2D

signal item_activated

var message_timer = 0.0
var message_interval = 3.0  # Show message every 3 seconds
var cabinet_player_in_area = false
var player = null
var has_given_item = false # New variable to track if item has been given

func _ready():
	print("🔵 Cabinet: Script loaded")
	await get_tree().create_timer(0.5).timeout
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("🔵 Cabinet: Signals connected")
	await get_tree().create_timer(0.5).timeout
	
	# Set collision properties
	collision_layer = 2  # Layer 2 for interactable objects
	collision_mask = 1   # Mask 1 for player
	print("🔵 Cabinet: Ready with collision layer:", collision_layer, " mask:", collision_mask)
	print("🔵 Cabinet: In computer group:", is_in_group("computer"))

func _process(delta):
	# if cabinet_player_in_area and Input.is_action_just_pressed("interact") and not has_given_item:
	# 	print("🔵 Cabinet: E key pressed while player in area")
	# 	open_puzzle_ui()
	pass # No direct input handling in cabinet script

func _on_body_entered(body: Node2D) -> void:
	print("🔵 Cabinet: Body entered:", body.name)
	await get_tree().create_timer(0.5).timeout
	print("🔵 Cabinet: Body is in player group:", body.is_in_group("player"))
	await get_tree().create_timer(0.5).timeout
	print("🔵 Cabinet: Body collision layer:", body.collision_layer)
	await get_tree().create_timer(0.5).timeout
	print("🔵 Cabinet: Body collision mask:", body.collision_mask)
	if body.is_in_group("player"):
		cabinet_player_in_area = true
		player = body
		message_timer = 0.0  # Reset timer when player enters
		print("🔵 Cabinet: Player entered area, cabinet in computer group:", is_in_group("computer"))
		# Set the player's nearby_cabinet reference
		body.nearby_cabinet = self
		print("🔵 Cabinet: Set player's nearby_cabinet reference")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("🔵 Cabinet: Player exited area")
		cabinet_player_in_area = false
		player = null
		message_timer = 0.0  # Reset timer when player exits
		# Clear the player's nearby_cabinet reference
		if body.nearby_cabinet == self:
			body.nearby_cabinet = null
			print("🔵 Cabinet: Cleared player's nearby_cabinet reference")

func open_puzzle_ui() -> void:
	print("🔵 Cabinet: Activating item")
	await get_tree().create_timer(0.5).timeout
	
	# Give copper wire to player using PlayerInventory
	print("🔵 Cabinet: Attempting to add copper wire to inventory")
	if PlayerInventory.add_item("Copper wire", 1):
		print("🔵 Cabinet: Successfully gave copper wire to player")
		has_given_item = true # Set to true after giving item
		await get_tree().create_timer(0.5).timeout
		# Disable the cabinet after giving the item
		# queue_free()
	else:
		print("🔵 Cabinet: ERROR - Failed to add copper wire to inventory")
