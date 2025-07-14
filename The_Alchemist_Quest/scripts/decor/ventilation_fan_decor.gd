extends Area2D

@export var fan_id: String = "ventilation_fan"
var is_activated: bool = false

func _ready():
	# Đăng ký với SaveLoadManager
	if get_node_or_null("/root/SaveLoadManager"):
		get_node("/root/SaveLoadManager").register_saveable_object(self)
		print("[VentilationFan] Đã đăng ký với SaveLoadManager")
	
	# Kiểm tra trạng thái từ GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.get("ventilation_system_state") != null:
		if game_manager.ventilation_system_state.has("is_ventilation_fixed") and game_manager.ventilation_system_state["is_ventilation_fixed"]:
			activate()
			print("[VentilationFan] Kích hoạt quạt từ GameManager")
		else:
			deactivate()
			print("[VentilationFan] Quạt ở trạng thái bình thường")
	else:
		$AnimatedSprite2D.play("default")
		print("[VentilationFan] Quạt khởi tạo với animation mặc định")

# Kích hoạt quạt (tốc độ cao)
func activate():
	is_activated = true
	$AnimatedSprite2D.play("activated")
	print("[VentilationFan] Quạt đã được kích hoạt")

# Đặt quạt về trạng thái bình thường
func deactivate():
	is_activated = false
	$AnimatedSprite2D.play("default")
	print("[VentilationFan] Quạt đã được đặt về trạng thái bình thường")

# Chuyển đổi trạng thái quạt
func toggle():
	if is_activated:
		deactivate()
	else:
		activate()

# Phương thức được gọi từ signal fan_activation_requested
func play(animation_name: String = "activated"):
	if animation_name == "activated":
		activate()
	else:
		$AnimatedSprite2D.play(animation_name)

# Lấy ID để sử dụng với SaveLoadManager
func get_saveable_id() -> String:
	return "fan_" + fan_id

# Lưu trạng thái
func save_state() -> Dictionary:
	var state = {
		"is_activated": is_activated,
		"current_animation": $AnimatedSprite2D.animation
	}
	print("[SaveSystem] Ventilation fan lưu trạng thái: activated=", is_activated)
	return state

# Tải trạng thái
func load_state(state: Dictionary) -> void:
	if state.has("is_activated"):
		is_activated = state["is_activated"]
		if is_activated:
			activate()
		else:
			deactivate()
		print("[SaveSystem] Ventilation fan tải trạng thái: activated=", is_activated)
	
	# Luôn kiểm tra animation để đảm bảo trạng thái hình ảnh chính xác
	if state.has("current_animation"):
		$AnimatedSprite2D.play(state["current_animation"])
		print("[SaveSystem] Ventilation fan tải animation:", state["current_animation"]) 