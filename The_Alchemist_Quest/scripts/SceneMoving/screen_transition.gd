extends CanvasLayer

signal transition_completed

func fade_out():
	$FadeToBlack.play("Fade_to_black")
	await $FadeToBlack.animation_finished
	emit_signal("transition_completed")
