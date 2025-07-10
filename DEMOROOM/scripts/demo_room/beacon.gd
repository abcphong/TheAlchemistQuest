extends AnimatedSprite2D
@onready var beacon: AnimatedSprite2D = $"."
@onready var danger_alarm: AudioStreamPlayer2D = $"../Node2D/Danger_Alarm"



func _ready():
	beacon.play()
	danger_alarm.play()
