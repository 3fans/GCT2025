class_name SelectionSlot
extends ItemSlotDisplay
## This is an independent slot that acts as the item selector for the player.
## In simpler terms, it's the item slot that is on the player's cursor.
## Handles the click interactions with slots.

## Display's offset from the mouse position.
@export var display_offset: Vector2 = Vector2(10, 10)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	Coordinator.slot_interacted.connect(on_slot_interacted)
	
func _process(_delta: float) -> void:
	# Constantly stick by the user's cursor.
	global_position = get_global_mouse_position() + display_offset

## This method handles the clicking interactions with other itemslots.
## Only call this if you need to simulate the player clicking on a slot,
## otherwise, 
func on_slot_interacted(event: InputEvent, clicked_slot: ItemSlot, root: Node) -> void:
	if root != Coordinator.get_root(self):
		# Ignore if the slot clicked is not the same minigame as self.
		return
		
	if event is InputEventMouseButton and event.is_pressed():
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			ItemTransfer.standard_transfer(slot, clicked_slot)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			ItemTransfer.alternate_transfer(slot, clicked_slot)
