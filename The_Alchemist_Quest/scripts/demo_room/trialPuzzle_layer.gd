@tool
class_name AnimatedTextureRect extends TextureRect

@export var sprites: SpriteFrames
@export var current_animation = "default"
@export var frame_index := 0 
@export_range(0.0, INF, 0.001) var speed_scale := 1.0
@export var auto_play := false
@export var playing := false
var refresh_rate = 2.0
var fps = 10.0
var frame_delta = 0

# Signal for animation completion
signal animation_finished(anim_name)

func _ready():
	if not sprites:
		print("❌ Error: No SpriteFrames assigned to AnimatedTextureRect")
		return
	fps = sprites.get_animation_speed(current_animation)
	refresh_rate = sprites.get_frame_duration(current_animation, frame_index)
	if auto_play:
		play()
	# Debug initial animation
	print("AnimatedTextureRect - Current Animation:", current_animation, "Frame:", frame_index, "FPS:", fps)

func _process(delta):
	if sprites == null or not playing:
		return
	if not sprites.has_animation(current_animation):
		playing = false
		print("❌ Error: Animation", current_animation, "not found in SpriteFrames")
		return
	
	get_animation_data(current_animation)
	frame_delta += (speed_scale * delta)
	if frame_delta >= refresh_rate / fps:
		texture = get_next_frame()

func play(animation_name: String = current_animation):
	if not sprites or not sprites.has_animation(animation_name):
		print("❌ Error: Cannot play animation", animation_name, "- not found")
		return
	frame_index = 0
	frame_delta = 0.0
	current_animation = animation_name
	get_animation_data(current_animation)
	playing = true
	print("🎬 Playing animation:", current_animation)

func get_animation_data(animation):
	fps = sprites.get_animation_speed(current_animation)
	refresh_rate = sprites.get_frame_duration(current_animation, frame_index)

func resume():
	playing = true
	print("▶️ Resumed animation:", current_animation)

func pause():
	playing = false
	print("⏸ Paused animation:", current_animation)

func get_next_frame():
	var frame_count = sprites.get_frame_count(current_animation)
	frame_index += 1
	if frame_index >= frame_count:
		if not sprites.get_animation_loop(current_animation):
			playing = false
			emit_signal("animation_finished", current_animation)
			print("🎬 Animation finished:", current_animation)
			return sprites.get_frame_texture(current_animation, frame_count - 1)
		else:
			frame_index = 0
	get_animation_data(current_animation)
	var frame_texture = sprites.get_frame_texture(current_animation, frame_index)
	if frame_texture:
		return frame_texture
	else:
		print("❌ Error: No texture for frame", frame_index, "in animation", current_animation)
		return null
