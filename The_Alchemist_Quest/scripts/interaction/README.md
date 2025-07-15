# InteractableBase - Item Pickup Module

Simple module for creating objects that give items when player presses E.

## Quick Setup

### Step 1: Create Script
```gdscript
extends InteractableBase

func _ready():
    item_name = "Your Item"
    item_quantity = 1
    super._ready()
```

### Step 2: Add to Scene
1. **Add Area2D node** to your scene
2. **Attach your script** to the Area2D node
3. **Add CollisionShape2D** as child of Area2D
4. **Set collision shape** - choose shape type (Rectangle, Circle, etc.)
5. **Set collision size** - adjust to match your object size
6. **Test collision** - make sure player can enter the area

### Step 3: Configure (Optional)
```gdscript
# Multiple use item
can_give_multiple = true

# Custom group
interaction_group = "my_items"
```

## Examples

### Basic Item Pickup
```gdscript
extends InteractableBase

func _ready():
    item_name = "Health Potion"
    item_quantity = 1
    super._ready()
```

### Item + UI (Advanced)
```gdscript
extends InteractableBase

@export var puzzle_ui_scene: PackedScene

func _ready():
    item_name = "Key"
    item_quantity = 1
    super._ready()

func _on_item_given():
    # Open UI after giving item
    if puzzle_ui_scene:
        var ui = puzzle_ui_scene.instantiate()
        get_tree().current_scene.add_child(ui)
```

## Export Variables
- `item_name`: Item to give
- `item_quantity`: How many to give
- `can_give_multiple`: Allow multiple pickups
- `interaction_group`: Group for detection

## Virtual Methods (Override if needed)
- `_on_item_given()`: Called after giving item
- `_on_player_entered()`: Called when player enters
- `_on_player_exited()`: Called when player exits 