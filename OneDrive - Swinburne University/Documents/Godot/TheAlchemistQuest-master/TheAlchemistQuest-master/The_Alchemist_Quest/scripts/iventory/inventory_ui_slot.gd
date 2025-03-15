extends Panel

@onready var item_visual:Sprite2D =$Panel/item_display
@onready var amount_text:Label = $Panel/item_display/Label

func update(slot:inventorySlot):
	if slot == null:  # Check if slot is null before accessing properties
		item_visual.visible = false
		amount_text.visible = false
		return 
		
	if !slot.item:
		item_visual.visible = false
		amount_text.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = slot.item.texture
		if slot.amount > 1:
			amount_text.visible = true
		amount_text.visible = true
		amount_text.text = str(slot.amount)
