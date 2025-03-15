extends Sprite2D


@onready var item_visual:Sprite2D = $itemDisplay

func update(item:inventoryItem):
	if !item:
		item_visual.visible = false
	else:
		item_visual.visible = true
		item_visual.texture = item.texture
