extends Area2D

var player = null
var can_interact = false
var has_given_item = false  # Track if item has been given
@export var puzzle_ui_scene: PackedScene  # Scene for the puzzle UI

signal item_given

func _ready():
	add_to_group("computer")
	print("🔵 Computer initialized")
	print("🔵 Computer collision layer:", collision_layer)
	print("🔵 Computer collision mask:", collision_mask)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up collision detection
	collision_layer = 2
	collision_mask = 1

func _process(_delta):
	if can_interact and Input.is_action_just_pressed("interact"):
		print("🔵 Computer interaction triggered")
		if not has_given_item:
			# Add item to player's inventory
			if PlayerInventory.add_item("Zinc bar", 1):
				print("✅ Successfully added Zinc bar to inventory")
				has_given_item = true
				open_puzzle_ui()
			else:
				print("❌ Failed to add item to inventory - Inventory might be full")
		
		# Open puzzle UI if available
		if puzzle_ui_scene:
			print("🔵 Opening puzzle UI")
			var puzzle_ui = puzzle_ui_scene.instantiate()
			get_tree().current_scene.add_child(puzzle_ui)
		else:
			print("❌ No puzzle UI scene assigned")

func _on_body_entered(body: Node2D) -> void:
	print("🔵 Computer: Body entered:", body.name)
	print("🔵 Computer: Body is in player group:", body.is_in_group("player"))
	print("🔵 Computer: Body collision layer:", body.collision_layer)
	print("🔵 Computer: Body collision mask:", body.collision_mask)
	
	if body.is_in_group("player"):
		print("🔵 Computer: Player entered area")
		can_interact = true
		player = body
		print("Player collision layer:", body.collision_layer, " Player collision mask:", body.collision_mask)

func _on_body_exited(body: Node2D) -> void:
	print("🔵 Computer: Player exited area")
	if body.is_in_group("player"):
		print("🴴 Player exited computer area")
		can_interact = false
		player = null 

func open_puzzle_ui() -> void:
	print("🔵 Computer: Giving item to player")
	emit_signal("item_given") 
