extends Node

@export var healthbar: AnimatedSprite2D
@export var HealthTimer: Timer
@export var player_sprite: AnimatedSprite2D

signal health_critical

var current_animation: String = "Green"
var is_invincible: bool = false # Trạng thái vô địch tạm thời
var invincible_duration: float = 5.0 # Thời gian vô địch (5 giây)

var animation_durations = {
	"Green": 30.0,
	"Orange": 30.0,
	"Red": 30.0
}

func _ready():
	print("✅ Health bar ready")
	add_to_group("HealthBar")
	current_animation = "Green"
	play_animation_once("Green")
	
	# Kết nối tín hiệu từ timer
	if HealthTimer:
		HealthTimer.timeout.connect(_on_health_timer_timeout)

func _on_health_timer_timeout():
	# Nếu đang trong trạng thái vô địch, không giảm sức khỏe
	if is_invincible:
		print("🛡️ Đang trong trạng thái vô địch, không giảm sức khỏe")
		HealthTimer.start(animation_durations[current_animation])
		return
	
	print("🔁 Timer timed out: " + current_animation)

	match current_animation:
		"Green":
			current_animation = "Orange"
			play_animation_once("Orange")
		"Orange":
			current_animation = "Red"
			play_animation_once("Red")
		"Red":
			current_animation = "Red_blink"
			play_red_blink_and_die()

# ✅ Chạy animation 1 lần rồi dừng ở frame cuối
func play_animation_once(anim_name: String):
	healthbar.play(anim_name)

	var frame_count = healthbar.sprite_frames.get_frame_count(anim_name)
	var fps = healthbar.sprite_frames.get_animation_speed(anim_name)
	var duration = float(frame_count) / fps

	await get_tree().create_timer(duration).timeout

	healthbar.stop()
	healthbar.frame = frame_count - 1

	HealthTimer.start(animation_durations[anim_name])


# ✅ Chạy red_blink, dừng và chết ngay
func play_red_blink_and_die():
	healthbar.play("Red_blink")

	var frame_count = healthbar.sprite_frames.get_frame_count("Red_blink")
	var fps = healthbar.sprite_frames.get_animation_speed("Red_blink")
	var duration = float(frame_count) / fps

	await get_tree().create_timer(duration).timeout

	healthbar.stop()
	healthbar.frame = frame_count - 1

	print("☠ Player ngất!")
	if player_sprite:
		player_sprite.play("die")

	emit_signal("health_critical")
	
	# Sau khi animation "die" kết thúc, respawn
	await get_tree().create_timer(2.0).timeout  # Đợi 2 giây để animation "die" hoàn thành
	respawn_player()

# Phục hồi sức khỏe người chơi về trạng thái ban đầu
func reset_health():
	current_animation = "Green"
	play_animation_once("Green")
	
	# Kích hoạt chế độ vô địch tạm thời
	activate_invincibility()

# Kích hoạt chế độ vô địch tạm thời
func activate_invincibility():
	is_invincible = true
	print("🛡️ Kích hoạt chế độ vô địch tạm thời trong", invincible_duration, "giây")
	
	# Hiệu ứng nhấp nháy để thể hiện trạng thái vô địch
	flash_player_sprite()
	
	# Sau thời gian vô địch, tắt chế độ này
	await get_tree().create_timer(invincible_duration).timeout
	is_invincible = false
	
	# Trả lại màu bình thường cho nhân vật
	if player_sprite:
		player_sprite.modulate = Color(1, 1, 1, 1)
	print("⚔️ Kết thúc chế độ vô địch tạm thời")

# Hiệu ứng nhấp nháy cho trạng thái vô địch
func flash_player_sprite():
	if not player_sprite:
		return
		
	var tween = create_tween().set_loops(10) # Nhấp nháy 10 lần
	tween.tween_property(player_sprite, "modulate", Color(1, 1, 1, 0.3), 0.2)
	tween.tween_property(player_sprite, "modulate", Color(1, 1, 1, 1), 0.2)

# Gọi respawn từ CheckpointManager
func respawn_player():
	# Đợi một nhịp frame để đảm bảo tất cả các animation đã hoàn thành  
	await get_tree().process_frame
	
	if CheckpointManager:
		print("⟲ Gọi respawn từ health bar")
		CheckpointManager.respawn_player()
	else:
		print("❌ Không tìm thấy CheckpointManager")
	
	# Reset health và kích hoạt chế độ vô địch đã được chuyển vào hàm reset_health
	reset_health()
	
	# Reset player animation
	if player_sprite and player_sprite.has_animation("idle"):
		player_sprite.play("idle")

# Lưu trạng thái thanh máu
func save_health_state() -> Dictionary:
	var state = {
		"current_animation": current_animation,
		"is_invincible": is_invincible
	}
	print("💾 Lưu trạng thái thanh máu: ", state)
	
	# Lưu trạng thái vào GameManager nếu có
	var game_manager = get_node_or_null("/root/GameManager") 
	if game_manager:
		# Sử dụng kỹ thuật an toàn để gán giá trịdw
		if game_manager.get_script():
			game_manager.set("health_state", state)
			print("💾 Đã lưu trạng thái thanh máu vào GameManager")
		else:
			print("⚠ Không thể lưu trạng thái vào GameManager: không có script")
	else:
		print("⚠ Không tìm thấy GameManager để lưu trạng thái")
	
	return state

# Tải trạng thái thanh máu
func load_health_state(state: Dictionary = {}) -> void:
	# Nếu không có state được cung cấp, tìm từ GameManager
	if state.is_empty():
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			# Kiểm tra xem thuộc tính health_state có tồn tại không
			if game_manager.get("health_state"):
				state = game_manager.health_state
				print("📂 Đã tải trạng thái thanh máu từ GameManager")
			else:
				print("⚠ GameManager không có thuộc tính health_state, sử dụng trạng thái mặc định")
	
	if state.has("current_animation"):
		current_animation = state["current_animation"]
		play_animation_once(current_animation)
		print("📂 Đã tải trạng thái thanh máu: ", current_animation)
		
	if state.has("is_invincible") and state["is_invincible"]:
		activate_invincibility()
