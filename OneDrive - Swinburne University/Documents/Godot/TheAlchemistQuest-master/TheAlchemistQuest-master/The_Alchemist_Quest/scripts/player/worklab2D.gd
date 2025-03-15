extends Area2D


@export var item:inventoryItem
var player = null

func _on_body_entered(body: Node2D) -> void:
	print ("Contact to work bench")
	player = body

func do_lab():
	player.collect(item)
