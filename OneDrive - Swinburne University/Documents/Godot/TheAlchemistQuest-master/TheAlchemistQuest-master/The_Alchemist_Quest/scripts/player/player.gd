extends CharacterBody2D


const SPEED = 100.0
@onready var animated_sprite = $AnimatedSprite2D



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
	
