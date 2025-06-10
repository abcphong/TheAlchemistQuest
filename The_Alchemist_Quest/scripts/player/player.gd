extends CharacterBody2D

signal position_changed(new_position: Vector2)

const SPEED = 100.0
@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea

var nearby_workbench: Node = null
var nearby_computer: Node = null
var nearby_cabinet: Node = null
var can_interact: bool = false
var last_position: Vector2

func _ready():
	add_to_group("player")
	print("🔵 Player initialized")
	print("🔵 Player collision layer:", collision_layer)
	print("🔵 Player collision mask:", collision_mask)
	print("🔵 DetectionArea collision layer:", detection_area.collision_layer)
	print("🔵 DetectionArea collision mask:", detection_area.collision_mask)
	print("🔵 DetectionArea monitoring:", detection_area.monitoring)
	print("🔵 DetectionArea monitorable:", detection_area.monitorable)
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Enable debug visualization
	detection_area.get_node("CollisionShape2D").debug_color = Color(1, 0, 0, 0.5)
	
	# Print initial state
	print("🔵 Initial state:")
	print("  - nearby_workbench:", nearby_workbench != null)
	print("  - nearby_computer:", nearby_computer != null)
	print("  - nearby_cabinet:", nearby_cabinet != null)
	
	last_position = global_position

func _physics_process(delta: float) -> void:
	#Get the input direction: -1 , 1
	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up","move_down")
	
	#Calculate velocity
	velocity.x = direction_x * SPEED
	velocity.y = direction_y * SPEED
	
	#Moving direction
	if velocity.length() > 0 :
		if abs(direction_x) > abs(direction_y):
			if (direction_x) > 0:
				animated_sprite.frame = 3
			else:
				animated_sprite.frame = 1
		else:
			if direction_y > 0:
				animated_sprite.frame = 0
			else:
				animated_sprite.frame = 2
	else:
		animated_sprite.frame = 0 
		
	move_and_slide()
	
	# Emit position changed signal if position has changed
	if global_position != last_position:
		position_changed.emit(global_position)
		last_position = global_position

func _process(delta):
	if Input.is_action_just_pressed("interact"):
		print("Nhấn E")
		print("🔵 nearby_workbench:", nearby_workbench != null)
		print("🔵 nearby_computer:", nearby_computer != null)
		print("🔵 nearby_cabinet:", nearby_cabinet != null)
		print("🔵 Player position:", global_position)
		
		# Debug: Check for any bodies in detection area
		var bodies = detection_area.get_overlapping_bodies()
		print("🔵 Bodies in detection area:", bodies.size())
		for body in bodies:
			print("  - Body:", body.name)
			print("    Group:", body.is_in_group("computer"))
			print("    Position:", body.global_position)
			print("    Distance:", global_position.distance_to(body.global_position))
			print("    Collision layer:", body.collision_layer)
			print("    Collision mask:", body.collision_mask)
			print("    Monitorable:", body.monitorable if body is Area2D else "N/A")
			print("    Monitoring:", body.monitoring if body is Area2D else "N/A")
		
		if nearby_workbench:
			print("🔵 Gọi open_puzzle_ui")
			nearby_workbench.open_puzzle_ui()
		elif nearby_computer:
			print("🔵 Interacting with computer")
			nearby_computer.open_puzzle_ui()
		elif nearby_cabinet:
			print("🔵 Interacting with cabinet")
			nearby_cabinet.open_puzzle_ui()
		else:
			print("❌ Không có nearby_workbench, computer, hoặc cabinet")

func _on_detection_area_body_entered(body: Node2D) -> void:
	print("🔵 DetectionArea body entered:", body.name)
	print("🔵 Body is in computer group:", body.is_in_group("computer"))
	print("🔵 Body collision layer:", body.collision_layer)
	print("🔵 Body collision mask:", body.collision_mask)
	print("🔵 Body position:", body.global_position)
	print("🔵 Player position:", global_position)
	print("🔵 Distance to body:", global_position.distance_to(body.global_position))
	
	if body.is_in_group("workbench"):
		nearby_workbench = body
		print("🔵 Player entered workbench area")
	elif body.is_in_group("computer"):
		if body.name == "ElectricalCabinet":
			nearby_cabinet = body
			print("🔵 Player entered cabinet area")
		else:
			nearby_computer = body
			print("🔵 Player entered computer area")

func _on_detection_area_body_exited(body: Node2D) -> void:
	print("🔵 DetectionArea body exited:", body.name)
	print("🔵 Body is in computer group:", body.is_in_group("computer"))
	print("🔵 Body position:", body.global_position)
	print("🔵 Player position:", global_position)
	print("🔵 Distance to body:", global_position.distance_to(body.global_position))
	
	if body.is_in_group("workbench"):
		nearby_workbench = null
		print("🔴 Player exited workbench area")
	elif body.is_in_group("computer"):
		if body.name == "ElectricalCabinet":
			nearby_cabinet = null
			print("🔴 Player exited cabinet area")
		else:
			nearby_computer = null
			print("🔴 Player exited computer area")
