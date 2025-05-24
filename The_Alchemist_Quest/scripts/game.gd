extends Node2D  # hoặc Node/Control gì đó, miễn là một node

func _ready():
	var inv = $UI/Inventory
	UserInterface.inventory_node = inv


func _input(event):
	if event.is_action_pressed("open_inventory"):
		UserInterface.toggle_inventory()
