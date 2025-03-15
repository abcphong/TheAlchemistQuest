extends Control

@onready var inventory:Inventory = preload("res://The_Alchemist_Quest/scripts/iventory/playerInventory.tres")
@onready var slots:Array = $NinePatchRect/GridContainer.get_children()

var is_open = false

func _ready():
	inventory.update.connect(update_slots)
	update_slots()
	close()
	
func update_slots():
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].update(inventory.slots[i])
	
func _process(delta):
	if Input.is_action_just_pressed("open_inventory"):
		if is_open:
			close()
		else:
			open()
func open():
	visible = true
	is_open = true
	
func close():
	visible = false
	is_open = false
