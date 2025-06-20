extends Node

# Lưu vị trí checkpoint mặc định ban đầu
var initial_checkpoint_position: Vector2 = Vector2(203, 189) # Vị trí ban đầu trong game.tscn
var current_checkpoint_position: Vector2 

func _ready():
	# Khởi tạo với checkpoint mặc định
	current_checkpoint_position = initial_checkpoint_position

# Đặt checkpoint mới
func set_checkpoint(position: Vector2):
	current_checkpoint_position = position
	print("✅ Checkpoint mới được đặt tại:", position)

# Lấy vị trí checkpoint hiện tại
func get_checkpoint() -> Vector2:
	return current_checkpoint_position

# Đưa người chơi về checkpoint 
func respawn_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		print("⟲ Đưa người chơi về checkpoint:", current_checkpoint_position)
		player.global_position = current_checkpoint_position
		# Gọi hàm recover_from_death nếu có  
		if player.has_method("recover_from_death"):
			player.recover_from_death()
		# Phục hồi trạng thái
		reset_health()

func reset_health():
	var health_bar = get_tree().get_first_node_in_group("HealthBar")
	if health_bar:
		print("⟲ Phục hồi sức khỏe người chơi")
		if health_bar.has_method("reset_health"):
			health_bar.reset_health() 