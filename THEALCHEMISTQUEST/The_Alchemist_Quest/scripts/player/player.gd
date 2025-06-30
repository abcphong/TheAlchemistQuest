extends CharacterBody2D

# ==== DI CHUYỂN ====
var speed = 100
var normal_speed = 100
var slow_speed = 50
var current_dir = ""

@export var current_animation: String = "Green"
@onready var animated_sprite = $AnimatedSprite2D
@export var player_sprite: AnimatedSprite2D  # Gắn sprite chính trong editor nếu không dùng $AnimatedSprite2D

# ==== TƯƠNG TÁC ====
var nearby_workbench: Node = null
var can_interact: bool = false

func _ready():
	var hb = get_node("/root/Game/UI/HealthBar")
	hb.connect("health_critical", Callable(self, "call_die_animation"))
	print("✅ Player đã kết nối với signal từ Health bar")

func _physics_process(delta):
	if player_sprite.animation != "die":
		player_movement(delta)

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
			current_dir = "right" if direction_x > 0 else "left"
		else:
			current_dir = "down" if direction_y > 0 else "up"
		play_anim(true)
	else:
		play_anim(false)

	move_and_slide()

func play_anim(moving: bool):
	var anim = player_sprite

	match current_dir:
		"right":
			anim.flip_h = false
			if moving:
				anim.play("walk_side")
			else:
				anim.play("idle")
				anim.frame = 3  # mặt phải
		"left":
			anim.flip_h = true
			if moving:
				anim.play("walk_side")
			else:
				anim.play("idle")
				anim.frame = 3  # mặt trái
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


# ==== TƯƠNG TÁC WORKBENCH ====
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		print("Nhấn E")
		if nearby_workbench:
			print("🔵 Gọi open_puzzle_ui")
			nearby_workbench.open_puzzle_ui()
		else:
			print("❌ Không có nearby_workbench")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Workbench":  # Hoặc kiểm tra bằng is Workbench nếu có script riêng
		nearby_workbench = body
		can_interact = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == nearby_workbench:
		nearby_workbench = null
		can_interact = false

# ==== CHẾT ====
func call_die_animation():
	print("☠ Gọi hoạt ảnh chết từ signal!")
	player_sprite.play("die")
	if player_sprite:
		player_sprite.play("die")
