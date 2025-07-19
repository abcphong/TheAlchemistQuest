extends Node

@export var healthbar: AnimatedSprite2D
@export var HealthTimer: Timer
@export var player_sprite: AnimatedSprite2D

signal health_critical

const MAX_HEALTH_TIME: float = 90.0
var remaining_time: float = MAX_HEALTH_TIME
var is_invincible: bool = false
var invincible_duration: float = 5.0
var is_dead: bool = false
var is_visible: bool = true  # Biến theo dõi trạng thái hiển thị

func _ready():
	print("✅ Health bar ready (Time-based)")
	add_to_group("HealthBar")
	
	# Kết nối với signal game_loaded từ SaveLoadManager
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager and not save_load_manager.is_connected("game_loaded", Callable(self, "_on_game_loaded")):
		save_load_manager.connect("game_loaded", Callable(self, "_on_game_loaded"))
		print("[HealthBar] Đã kết nối với signal game_loaded")
	
	load_health_state()
	_update_display()

	if HealthTimer:
		HealthTimer.wait_time = 1.0
		HealthTimer.one_shot = false
		HealthTimer.timeout.connect(_on_health_timer_timeout)
		
		# Chỉ bắt đầu timer nếu thanh máu đang hiển thị
		if is_visible:
			HealthTimer.start()
		else:
			if healthbar:
				healthbar.hide()

# Hàm được gọi khi game được tải thành công
func _on_game_loaded():
	print("[HealthBar] Nhận được signal game_loaded. Đang cập nhật trạng thái.")
	load_health_state()
	_update_display()

func _on_health_timer_timeout():
	if is_invincible or is_dead:
		return

	remaining_time -= 1
	if remaining_time < 0:
		remaining_time = 0

	_update_display()
	save_health_state()

	if remaining_time <= 0:
		_trigger_death_sequence()

func _update_display():
	var new_anim = ""
	if remaining_time > 60:
		new_anim = "Green"
	elif remaining_time > 30:
		new_anim = "Orange"
	elif remaining_time > 0:
		new_anim = "Red"
	else:
		new_anim = "Red_blink"

	if healthbar.animation != new_anim:
		healthbar.play(new_anim)

func _trigger_death_sequence():
	if is_dead: return
	is_dead = true
	
	print("☠ Player ngất!")
	healthbar.play("Red_blink")
	emit_signal("health_critical")
	
	await get_tree().create_timer(2.0).timeout
	
	# Kiểm tra trạng thái ventilation puzzle
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.ventilation_system_state.has("is_ventilation_fixed") and not game_manager.ventilation_system_state["is_ventilation_fixed"]:
		print("⚠️ Người chơi chết trước khi sửa xong hệ thống thông gió! Khởi động lại game...")
		restart_game()
	else:
		respawn_player()

# Hàm restart game từ đầu
func restart_game():
	# Reset các biến toàn cục
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager:
		checkpoint_manager.current_checkpoint_position = checkpoint_manager.initial_checkpoint_position
		print("⟲ Đã reset checkpoint về vị trí ban đầu:", checkpoint_manager.initial_checkpoint_position)
	
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Sử dụng phương thức reset_to_initial_state mới
		game_manager.reset_to_initial_state()
	
	# Reset SaveLoadManager
	var save_load_manager = get_node_or_null("/root/SaveLoadManager")
	if save_load_manager:
		save_load_manager.reset_to_initial_state()
	
	# Reset inventory và thêm các item mẫu ban đầu
	var player_inventory = get_node_or_null("/root/PlayerInventory")
	if player_inventory:
		# Reset inventory và hotbar
		for i in range(player_inventory.NUM_INVENTORY_SLOTS):
			player_inventory.inventory[i] = [null, 0]
		for i in range(player_inventory.NUM_HOTBARS_SLOTS):
			player_inventory.hotbar[i] = ["", 0]
			
		# Thêm các item mẫu ban đầu giống như lúc mới vào game
		# Theo cấu hình trong playerInventory.gd
		player_inventory.inventory = {
			0: ["Copper wire", 1],
			1: ["CuSO4", 1],
			2: ["Electric wire", 2],
			3: ["ZnSO4", 1],
			4: ["Zinc bar", 1],
			5: ["Salt bridge", 1],
			6: [null, 0],
			7: [null, 0],
			8: [null, 0]  # Thêm slot 8 để đủ NUM_INVENTORY_SLOTS
		}
		
		print("⟲ Đã reset PlayerInventory và thêm các item mẫu ban đầu")
	
	# Tải lại scene game từ đầu
	print("🔄 Đang khởi động lại game từ đầu...")
	get_tree().change_scene_to_file("res://The_Alchemist_Quest/scences/game.tscn")

func reset_health():
	remaining_time = MAX_HEALTH_TIME
	is_dead = false
	_update_display()
	activate_invincibility()

func activate_invincibility():
	is_invincible = true
	print("🛡️ Kích hoạt chế độ vô địch tạm thời trong", invincible_duration, "giây")
	flash_player_sprite()
	
	await get_tree().create_timer(invincible_duration).timeout
	is_invincible = false
	if player_sprite:
		player_sprite.modulate = Color.WHITE
	print("⚔️ Kết thúc chế độ vô địch tạm thời")

func flash_player_sprite():
	if not player_sprite: return
	var tween = create_tween().set_loops(10)
	tween.tween_property(player_sprite, "modulate", Color(1, 1, 1, 0.3), 0.25)
	tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.25)

func respawn_player():
	await get_tree().process_frame
	if get_node_or_null("/root/CheckpointManager"):
		get_node("/root/CheckpointManager").respawn_player()
		reset_health()
	else:
		print("❌ Không tìm thấy CheckpointManager")

# Ẩn thanh máu và dừng timer
func hide_health_bar():
	is_visible = false
	if HealthTimer:
		HealthTimer.stop()
	if healthbar:
		healthbar.hide()
	save_health_state()
	print("🛑 Đã ẩn thanh máu")

# Hiển thị thanh máu và bắt đầu timer
func show_health_bar():
	is_visible = true
	if healthbar:
		healthbar.show()
	if HealthTimer:
		HealthTimer.start()
	save_health_state()
	print("✅ Đã hiển thị thanh máu")

func save_health_state():
	var state = {
		"remaining_time": remaining_time,
		"is_visible": is_visible
	}
	var game_manager = get_node_or_null("/root/GameManager") 
	if game_manager:
		game_manager.health_state = state
		# Giảm bớt log để tránh spam console mỗi giây
		# print("💾 Đã lưu trạng thái thanh máu vào GameManager:", state)

func load_health_state():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.get("health_state") != null:
		var loaded_state = game_manager.health_state
		if loaded_state.has("remaining_time"):
			remaining_time = loaded_state["remaining_time"]
			print("📂 Đã tải trạng thái thanh máu từ GameManager:", remaining_time)
		
		if loaded_state.has("is_visible"):
			is_visible = loaded_state["is_visible"]
			if not is_visible:
				if healthbar:
					healthbar.hide()
				if HealthTimer:
					HealthTimer.stop()
				print("📂 Đã tải trạng thái hiển thị thanh máu: ẩn")
			else:
				print("📂 Đã tải trạng thái hiển thị thanh máu: hiển thị")
