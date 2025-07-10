extends Node2D

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $BGM
@onready var walk_player: AudioStreamPlayer2D = $walking
@export_node_path var player_path: NodePath
@onready var player: CharacterBody2D = get_node(player_path)


func _ready() -> void:
	audio_stream_player_2d.play()

func _physics_process(delta: float) -> void:
	# check if the player is actually moving
	var is_moving = player.velocity.length() > 0.0

	if is_moving:
		# if not already playing, start the footsteps
		if not walk_player.playing:
			walk_player.play()
	else:
		# if stopped moving, stop the footsteps
		if walk_player.playing:
			walk_player.stop()
