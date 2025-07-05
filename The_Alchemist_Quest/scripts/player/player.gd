extends CharacterBody2D

# ==== DI CHUYỂN ====
var speed = 100
var normal_speed = 100
var slow_speed = 50
var current_dir = ""
var is_recovering = false # Biến để kiểm soát trạng thái phục hồi

@export var current_animation: String = "Green"
@onready var animated_sprite = $AnimatedSprite2D
@export var player_sprite: AnimatedSprite2D  # Gắn sprite chính trong editor nếu không dùng $AnimatedSprite2D

# ==== TƯƠNG TÁC ====
var nearby_workbench: Node = null
var can_interact: bool = false

func _ready():
	var health_bars = get_tree().get_nodes_in_group("HealthBar")
	if not health_bars.is_empty():
		var hb = health_bars[0]
		if not hb.is_connected("health_critical", Callable(self, "call_die_animation")):
			hb.connect("health_critical", Callable(self, "call_die_animation"))
			print("[Player] Đã kết nối với signal từ Health bar")
	else:
		print("[Player] Không tìm thấy HealthBar trong group 'HealthBar'")
	
	add_to_group("Player")
	
	# Lưu vị trí hiện tại làm checkpoint ban đầu
	if get_node_or_null("/root/CheckpointManager"):
		get_node("/root/CheckpointManager").set_checkpoint(global_position)
	
	# Đăng ký với SaveLoadManager để lưu/tải trạng thái
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)

# Lưu trạng thái của player
func save_state() -> Dictionary:
	var state = {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"current_dir": current_dir,
		"current_animation": current_animation,
		"is_recovering": is_recovering
	}
	print("[SaveSystem] Player lưu trạng thái: pos=" + str(global_position))
	return state

# Tải trạng thái của player
func load_state(state: Dictionary) -> void:
	if state.has("position_x") and state.has("position_y"):
		global_position.x = state["position_x"]
		global_position.y = state["position_y"]
	
	if state.has("current_dir"):
		current_dir = state["current_dir"]
	
	if state.has("current_animation"):
		current_animation = state["current_animation"]
	
	if state.has("is_recovering"):
		is_recovering = state["is_recovering"]
		$CollisionShape2D.disabled = is_recovering
	
	print("[SaveSystem] Player tải trạng thái: pos=" + str(global_position))

# Lấy ID của player
func get_saveable_id() -> String:
	return "player"

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
	# Loại bỏ kiểm tra phòng security
	
	if Input.is_action_just_pressed("interact"):
		print("[DEBUG-PLAYER] Nút tương tác được nhấn")
		# Thêm điều kiện can_interact để đảm bảo người chơi vẫn đang trong vùng tương tác
		if nearby_workbench != null and is_instance_valid(nearby_workbench) and can_interact:
			print("[DEBUG-PLAYER] Tìm thấy workbench hợp lệ:", nearby_workbench.name, " - workbench_id:", nearby_workbench.workbench_id)
			print("[DEBUG-PLAYER] Gọi hàm open_puzzle_ui() từ workbench")
			nearby_workbench.open_puzzle_ui()
		else:
			print("[DEBUG-PLAYER] Không tìm thấy workbench hợp lệ để tương tác")
			if nearby_workbench != null and !is_instance_valid(nearby_workbench):
				print("[DEBUG-PLAYER] Đối tượng tương tác không còn hợp lệ")
				nearby_workbench = null
				can_interact = false  # Reset can_interact khi nearby_workbench không còn hợp lệ

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Workbench") or body.name == "LabWorkbench":
		nearby_workbench = body
		can_interact = true
		print("[DEBUG-PLAYER] Đã vào vùng workbench:", body.name)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == nearby_workbench:
		nearby_workbench = null
		can_interact = false
		print("[DEBUG-PLAYER] Đã rời khỏi vùng workbench:", body.name)

# ==== CHẾT ====
func call_die_animation():
	print("[Player] Kích hoạt animation ngất")
	is_recovering = true
	player_sprite.play("die")
	
	# Tạm thời vô hiệu hóa va chạm
	$CollisionShape2D.disabled = true
	
	# Sau khi animation kết thúc, đánh dấu đã hồi phục
	await player_sprite.animation_finished
	# is_recovering sẽ được reset khi respawn

# Reset player về trạng thái bình thường (được gọi từ checkpoint manager)
func recover_from_death():
	is_recovering = false
	player_sprite.play("idle")
	# Kích hoạt lại va chạm
	$CollisionShape2D.disabled = false
	print("[Player] Người chơi đã hồi phục")
	
# Reset các tham chiếu tương tác (được gọi từ SaveLoadManager)
func reset_interaction_references():
	print("[SaveSystem] Làm mới các tham chiếu tương tác của player")
	nearby_workbench = null
	can_interact = false
