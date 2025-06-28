extends Node

@export var healthbar: AnimatedSprite2D
@export var HealthTimer: Timer
@export var player_sprite: AnimatedSprite2D

signal health_critical

var current_animation: String = "Green"

var animation_durations = {
	"Green": 100.0,
	"Orange": 100.0,
	"Red": 100.0
}

func _ready():
	print("✅ Health bar ready")
	current_animation = "Green"
	play_animation_once("Green")

func _on_health_timer_timeout():
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

	print("☠ Player chết!")
	if player_sprite:
		player_sprite.play("die")

	emit_signal("health_critical")
