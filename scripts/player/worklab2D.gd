extends Area2D


var player = null

func _on_body_entered(body: Node2D) -> void:
	print ("Contact to work bench")
	player = body
