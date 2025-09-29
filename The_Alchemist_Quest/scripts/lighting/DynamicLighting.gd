extends Node2D

class_name DynamicLighting

# Properties
@export var enabled: bool = true
@export var light_radius: float = 200.0
@export var light_color: Color = Color(1, 1, 1, 1)
@export var light_offset: Vector2 = Vector2(0, 0) # New: Offset for the light position

# Nodes
var player_light: PointLight2D
var player: Node2D
var canvas_modulate: CanvasModulate # New: For global darkness

func _init():
	# New: Create the global darkness overlay
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0, 0, 0, 1.0) # Start fully dark
	add_child(canvas_modulate)
	
	# Create the player light
	player_light = PointLight2D.new()
	player_light.color = light_color
	player_light.texture = create_light_texture()
	player_light.texture_scale = 1.0
	player_light.enabled = true
	player_light.shadow_enabled = true
	player_light.shadow_color = Color(0, 0, 0, 0.2)
	
	# Add nodes to the scene
	add_child(player_light)

func _ready():
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	if player:
		player_light.global_position = player.global_position + light_offset # Apply offset
	
	# Connect to the player's movement
	if player:
		player.connect("position_changed", _on_player_moved)

func _process(_delta):
	if enabled and player:
		player_light.global_position = player.global_position + light_offset # Apply offset

func create_light_texture() -> Texture2D:
	# Create a radial gradient texture for the light
	var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(128, 128)
	var radius = 128.0
	
	for x in range(256):
		for y in range(256):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= radius:
				var alpha = 1.0 - (distance / radius)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

# New: Function to set global darkness (0.0 = fully visible, 1.0 = fully dark)
func set_darkness(factor: float):
	canvas_modulate.color = Color(factor, factor, factor, 1.0)

func set_enabled(value: bool):
	enabled = value
	canvas_modulate.visible = value # New: Toggle canvas_modulate visibility
	player_light.enabled = value

func set_light_radius(radius: float):
	light_radius = radius
	player_light.texture_scale = radius / 128.0  # Adjust scale based on texture size

func set_light_color(color: Color):
	light_color = color
	player_light.color = color

func _on_player_moved(new_position: Vector2):
	if enabled:
		player_light.global_position = new_position + light_offset # Apply offset

# Thêm các hàm tiện ích bật/tắt blackout theo trạng thái "điện"
func power_outage_on():
	# Bật blackout: bật overlay tối + bật đèn pin người chơi
	set_enabled(true)
	# 0.0 = tối đen, 1.0 = sáng bình thường (theo logic CanvasModulate)
	set_darkness(0.0)
	# Tuỳ chỉnh bán kính ánh sáng khi mất điện
	set_light_radius(60.0)

func power_restore_on():
	# Điện trở lại: tắt overlay tối và tắt đèn pin người chơi
	# Về mặt kỹ thuật: tắt overlay là đủ, nhưng có thể setDarkness(1.0) để rõ ràng
	set_darkness(1.0)
	set_enabled(false)

func apply_power_state(is_power_on: bool):
	if is_power_on:
		power_restore_on()
	else:
		power_outage_on()
