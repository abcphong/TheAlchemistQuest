extends CharacterBody2D

# ==== EXPORTS & CONSTANTS ====
@export var dialog_key: String = "Player"
@export var current_animation: String = "Green"
@export var player_sprite: AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var user_interface = $"../UserInterface"
@onready var detection_area = $DetectionArea


const SPEED = 100.0
var normal_speed = 100
var slow_speed = 50
var speed = SPEED

# ==== MOVEMENT & STATE ====
var current_dir = ""
var is_moving = false
var is_recovering = false
var last_position: Vector2
signal position_changed(new_position: Vector2)

# ==== INTERACTION ====
var nearby_workbench: Node2D = null
var nearby_computer: Node = null
var nearby_cabinet: Node = null
var can_interact: bool = false
var can_open_main_inventory: bool = true
var is_in_puzzle_mode: bool = false

func _ready():
	# Initialize state
	can_open_main_inventory = true
	is_in_puzzle_mode = false
	speed = normal_speed
	
	var workbenches = get_tree().get_nodes_in_group("workbench")
	for workbench in workbenches:
		if workbench.has_signal("player_entered"):
			workbench.player_entered.connect(_on_workbench_entered)
			workbench.player_exited.connect(_on_workbench_exited)
	

	# Health bar connection
	var health_bars = get_tree().get_nodes_in_group("HealthBar")
	if not health_bars.is_empty():
		var hb = health_bars[0]
		if not hb.is_connected("health_critical", Callable(self, "call_die_animation")):
			hb.connect("health_critical", Callable(self, "call_die_animation"))
			print("[Player] Connected to HealthBar signal")
	
	# Groups and detection area
	add_to_group("Player")
	add_to_group("player")
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
		detection_area.get_node("CollisionShape2D").debug_color = Color(1, 0, 0, 0.5)

	
	# Checkpoint and save system
	if get_node_or_null("/root/CheckpointManager"):
		get_node("/root/CheckpointManager").set_checkpoint(global_position)
	
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)
	
	# Dialog system
	if DialogPlayer and is_instance_valid(DialogPlayer):
		DialogPlayer.connect("dialog_finished", _on_dialog_finished)
	
	last_position = global_position

func _physics_process(delta):
	if player_sprite.animation != "die" and not is_recovering:
		player_movement(delta)
	else:
		# Khi đang ngất hoặc đang phục hồi, vô hiệu hóa va chạm
		velocity = Vector2.ZERO

func player_movement(_delta):
	velocity = Vector2.ZERO

	# Giảm tốc nếu máu yếu
	speed = slow_speed if current_animation in ["Red", "Red_blink"] else normal_speed

	# Input WASD (đã được ánh xạ trong InputMap)
	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up", "move_down")

	velocity.x = direction_x * speed
	velocity.y = direction_y * speed

	# Xác định hướng chuyển động
	if velocity.length() > 0:
		if abs(direction_x) > abs(direction_y):
			if direction_x > 0:  # Moving right
				current_dir = "right"
				player_sprite.flip_h = true  # Show normal animation
			else:  # Moving left
				current_dir = "left"
				player_sprite.flip_h = false  # Flip horizontally
		else:
			current_dir = "down" if direction_y > 0 else "up"
		play_anim(true)
	else:
		play_anim(false)

	move_and_slide()

func play_anim(moving: bool):
	var anim = player_sprite

	match current_dir:
		"right", "left":
			if moving:
				anim.play("walk_side")
				# Maintain the flip state from player_movement
			else:
				anim.play("idle")
				# Set frame based on last horizontal direction
				anim.frame = 3  # Right-facing frame
				anim.flip_h = (current_dir == "left")  # Flip if facing left
		"down":
			anim.flip_h = false
			if moving:
				anim.play("walk_front")
			else:
				anim.play("idle")
				anim.frame = 0  # mặt trước
		"up":
			anim.flip_h = false
			if moving:
				anim.play("walk_back")
			else:
				anim.play("idle")
				anim.frame = 2  # mặt sau

func _process(delta):
	# Handle interaction with all interactable objects
	if Input.is_action_just_pressed("interaction") or Input.is_action_just_pressed("interaction"):
		print("[DEBUG-PLAYER] Interaction button pressed")
		print("Can interact:", can_interact)
		print("Nearby workbench valid:", is_instance_valid(nearby_workbench))
		if nearby_workbench:
			print("Workbench has method:", nearby_workbench.has_method("open_puzzle_ui"))
			print("Workbench path:", nearby_workbench.get_path())
		
		if can_interact:
			if nearby_workbench != null and is_instance_valid(nearby_workbench):
				handle_workbench_interaction()
			elif nearby_computer != null and is_instance_valid(nearby_computer):
				print("[DEBUG-PLAYER] Player tương tác với computer (handled by InteractableBase)")
				nearby_computer._on_item_given()
			elif nearby_cabinet != null and is_instance_valid(nearby_cabinet):
				print("[DEBUG-PLAYER] Player tương tác với cabinet (handled by InteractableBase)")
				nearby_cabinet._on_item_given()
	
	# Handle main inventory toggle
	if can_open_main_inventory and Input.is_action_just_pressed("open_inventory"):
		user_interface.toggle_inventory()
		print("Inventory toggled - visible:", user_interface.inventory_node.visible)
	


func _on_workbench_entered(player_node):
	if player_node == self:
		can_interact = true

func _on_workbench_exited(player_node):
	if player_node == self:
		can_interact = false
		nearby_workbench = null

func handle_workbench_interaction():
	if not is_instance_valid(nearby_workbench):
		return

	nearby_workbench.open_puzzle_ui()
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	print("[DEBUG-PLAYER] DetectionArea body entered:", body.name)
	
	if body.is_in_group("Workbench") or body.is_in_group("workbench") or body.name == "LabWorkbench":
		nearby_workbench = body
		can_interact = true
		print("[DEBUG-PLAYER] Entered workbench area:", body.name)
	elif body.is_in_group("computer"):
		if body.name == "ElectricalCabinet":
			nearby_cabinet = body
			print("[DEBUG-PLAYER] Entered cabinet area")
		else:
			nearby_computer = body
			print("[DEBUG-PLAYER] Entered computer area")

func _on_detection_area_body_exited(body: Node2D) -> void:
	print("[DEBUG-PLAYER] DetectionArea body exited:", body.name)
	
	if body == nearby_workbench or body.is_in_group("Workbench") or body.is_in_group("workbench"):
		nearby_workbench = null
		can_interact = false
		print("[DEBUG-PLAYER] Left workbench area:", body.name)
	elif body.is_in_group("computer"):
		if body == nearby_cabinet:
			nearby_cabinet = null
			print("[DEBUG-PLAYER] Left cabinet area")
		elif body == nearby_computer:
			nearby_computer = null
			print("[DEBUG-PLAYER] Left computer area")

# ==== DEATH & RECOVERY ====
func call_die_animation():
	print("[Player] Triggering death animation")
	is_recovering = true
	player_sprite.play("die")
	$CollisionShape2D.disabled = true
	await player_sprite.animation_finished

func recover_from_death():
	is_recovering = false
	player_sprite.play("idle")
	$CollisionShape2D.disabled = false
	print("[Player] Player has recovered")

# ==== SAVE/LOAD SYSTEM ====
func save_state() -> Dictionary:
	var state = {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"current_dir": current_dir,
		"current_animation": current_animation,
		"is_recovering": is_recovering,
		"can_open_main_inventory": can_open_main_inventory,
		"is_in_puzzle_mode": is_in_puzzle_mode
	}
	print("[SaveSystem] Player saved state: pos=" + str(global_position))
	return state

func load_state(state: Dictionary) -> void:
	if state.has("position_x") and state.has("position_y"):
		global_position.x = state["position_x"]
		global_position.y = state["position_y"]
	
	current_dir = state.get("current_dir", "")
	current_animation = state.get("current_animation", "Green")
	is_recovering = state.get("is_recovering", false)
	can_open_main_inventory = state.get("can_open_main_inventory", true)
	is_in_puzzle_mode = state.get("is_in_puzzle_mode", false)
	
	if is_recovering:
		$CollisionShape2D.disabled = true
	
	print("[SaveSystem] Player loaded state: pos=" + str(global_position))

func get_saveable_id() -> String:
	return "player"

func reset_interaction_references():
	print("[SaveSystem] Refreshing player interaction references")
	nearby_workbench = null
	nearby_computer = null
	nearby_cabinet = null
	can_interact = false
	

# ==== DIALOG SYSTEM ====
func _on_dialog_finished():
	print("[Player] Dialog finished, resuming player input")
