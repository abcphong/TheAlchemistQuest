extends Node2D
class_name EButton

# Animation settings
@export var fade_duration: float = 0.3
@export var scale_animation: bool = true
@export var pulse_effect: bool = true

# Internal variables
var is_visible: bool = false
var fade_tween: Tween
var pulse_tween: Tween
var parent_detection_area: Area2D

func _ready():
	# Initially hide the button
	visible = false
	modulate.a = 0.0
	
	# Find parent's DetectionArea automatically
	_connect_to_detection_area()

func _connect_to_detection_area():
	var parent_node = get_parent()
	
	# Try to find DetectionArea in parent
	var detection_area = parent_node.get_node_or_null("DetectionArea")
	
	if detection_area and detection_area is Area2D:
		parent_detection_area = detection_area as Area2D
		
		# Connect signals
		parent_detection_area.body_entered.connect(_on_player_entered)
		parent_detection_area.body_exited.connect(_on_player_exited)
		
		print("🔗 EButton connected to DetectionArea: ", detection_area.name)
	else:
		# If no DetectionArea found, try parent itself if it's Area2D
		if parent_node is Area2D:
			parent_detection_area = parent_node as Area2D
			parent_detection_area.body_entered.connect(_on_player_entered)
			parent_detection_area.body_exited.connect(_on_player_exited)
			print("🔗 EButton connected to parent Area2D: ", parent_node.name)
		else:
			print("⚠️ EButton: No DetectionArea or Area2D found in parent!")

func _on_player_entered(body: Node2D):
	if body.is_in_group("player"):
		show_button()

func _on_player_exited(body: Node2D):
	if body.is_in_group("player"):
		hide_button()

func show_button():
	if is_visible:
		return
	
	is_visible = true
	visible = true
	
	# Stop any existing animations
	if fade_tween:
		fade_tween.kill()
	
	# Create fade in animation
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	
	# Fade in
	modulate.a = 0.0
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	
	# Scale animation
	if scale_animation:
		scale = Vector2.ZERO
		fade_tween.tween_property(self, "scale", Vector2.ONE, fade_duration)
		fade_tween.tween_method(_bounce_effect, 0.0, 1.0, fade_duration)
	
	# Start pulse effect after fade in
	if pulse_effect:
		fade_tween.tween_callback(_start_pulse).set_delay(fade_duration)
	
	print("👁️ EButton shown")

func hide_button():
	if not is_visible:
		return
	
	is_visible = false
	
	# Stop pulse effect
	if pulse_tween:
		pulse_tween.kill()
	
	# Stop any existing animations
	if fade_tween:
		fade_tween.kill()
	
	# Create fade out animation
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	
	# Fade out
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	# Scale out
	if scale_animation:
		fade_tween.tween_property(self, "scale", Vector2.ZERO, fade_duration)
	
	# Hide when animation complete
	fade_tween.tween_callback(func(): visible = false).set_delay(fade_duration)
	
	print("🫥 EButton hidden")

func _bounce_effect(progress: float):
	# Create bounce effect during scale animation
	var bounce = sin(progress * PI * 2) * 0.1 * (1.0 - progress) + 1.0
	scale = Vector2.ONE * bounce

func _start_pulse():
	if not pulse_effect or not is_visible:
		return
	
	# Create pulsing effect
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(self, "modulate:a", 0.6, 0.8)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.8)

func interaction_triggered():
	"""Call this when player interacts for visual feedback"""
	if not is_visible:
		return
	
	# Quick scale punch effect
	var feedback_tween = create_tween()
	feedback_tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.1)
	feedback_tween.tween_property(self, "scale", Vector2.ONE, 0.15)

# Public methods for manual control
func force_show():
	show_button()

func force_hide():
	hide_button()

func is_button_visible() -> bool:
	return is_visible

func stop_pulse():
	if pulse_tween:
		pulse_tween.kill()
		modulate.a = 1.0
