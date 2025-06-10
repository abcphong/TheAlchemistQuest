extends Node2D  # hoặc Node/Control gì đó, miễn là một node

@onready var lighting_system = $DynamicLighting

func _ready():
	var inv = $UI/Inventory
	UserInterface.inventory_node = inv

	# Initialize lighting system
	if lighting_system:
		# Set initial lighting parameters
		lighting_system.set_light_radius(50.0)  # Even smaller light radius
		lighting_system.set_light_color(Color(1, 0.95, 0.9))  # Very slight warm tint
		lighting_system.set_darkness(0.0)  # Almost no global darkness, just the light effect
		lighting_system.light_offset = Vector2(0, -10) # Adjust light position slightly upwards

func _input(event):
	pass
