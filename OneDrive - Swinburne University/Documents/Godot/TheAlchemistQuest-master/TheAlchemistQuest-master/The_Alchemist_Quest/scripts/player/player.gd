extends CharacterBody2D


const SPEED = 100.0
@onready var animated_sprite = $AnimatedSprite2D

@export var inventory:Inventory


func _physics_process(delta: float) -> void:
	
	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up","move_down")
	
	velocity.x = direction_x * SPEED
	velocity.y = direction_y * SPEED
	

	move_and_slide()
	
	
func collect(item):
	inventory.insert(item)
