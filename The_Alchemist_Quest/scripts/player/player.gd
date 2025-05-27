extends CharacterBody2D


const SPEED = 100.0
@onready var animated_sprite = $AnimatedSprite2D

var nearby_workbench: Node = null
var can_interact: bool = false

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
	
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		print("Nhấn E")
		if nearby_workbench:
			print("🔵 Gọi open_puzzle_ui")
			nearby_workbench.open_puzzle_ui()
		else:
			print("❌ Không có nearby_workbench")

func _on_detection_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_detection_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
