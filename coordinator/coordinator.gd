extends Node

## Emitted when a minigame was clicked. 
## Provides the miniframe object around the minigame that was clicked.
signal miniframe_clicked(miniframe: Miniframe)

## Emitted when any slot is interacted with anywhere.
## Provides the click event, the slot that was clicked
signal slot_interacted(event: InputEvent, slot: ItemSlot, root: Node)

@export var inventory: ArrayInventory

var miniframes: Array[Miniframe] = []:
	set(value):
		push_error("Attempted to set value of miniframes field in Coordinator directly!")

# TODO: Add static typing when Godot 4.4 comes out.
## Inventory managers. Maps the "root" of an inventory manager to the inventory manager. 
## Use [method get_root_of] for finding the root.
var inventory_managers: Dictionary = {}:
	set(value):
		push_error("Attempted to set value of inventory_managers field in Coordinator directly!")

func in_collage() -> bool:
	var main_node = get_node_or_null("/root/Collage")
	return is_instance_valid(main_node) and main_node is Collage

## Gets the local minigame root for the node given.
## For consistency with the rest of Godot, the "root" is the node right above 
## the root node of scene. 
## For most nodes, proper usage is [code]MinigameManager.get_root_of(self)[/code]
## Returns the global root if running from outside the collage scene.
## Returns the global root if called outside of any minigames but still inside the Collage.
func get_root_of(node: Node) -> Node:
	# This is to allow games to run in their own independent scenes for testing.
	if not in_collage():
		return get_tree().root
	
	# Normal case	
	for miniframe in miniframes:
		if miniframe.is_ancestor_of(node):
			return miniframe.viewport

	return get_tree().root
	
func get_inventory_manager(node: Node) -> Node:
	return inventory_managers[get_root_of(node)]

## Registers a miniframe to the manager.
func register_miniframe(miniframe: Miniframe) -> void:
	if not is_instance_valid(miniframe):
		push_warning("Attempted to register invalid instance to Coordinator!")
		return
	if miniframe in miniframes:
		push_warning("Attempted to register miniframe [%s] that was already registered!" % miniframe.name)
		return
		
	miniframe.enabled = false # Don't want minigames running until they're focused.
	miniframe.clicked.connect(miniframe_clicked.emit)
	miniframes.append(miniframe)
	
## Alert the coordinator that a slot has been clicked.
## This should be called from the Control node that was clicked.
## That control node should also be passed as [param clicked_node]
func alert_slot_interacted(event: InputEvent, slot: ItemSlot, clicked_node: Node) -> void:
	if not is_instance_valid(clicked_node):
		push_error("Invalid clicked_node parameter on method alert_slot_interacted!")
		return
	if not is_instance_valid(slot):
		push_error("Invalid slot parameter on method alert_slot_interacted")
		return
	
	var root: Node = get_root_of(clicked_node)
	slot_interacted.emit(event, slot, root)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Clean up any minigames that have become invalid.
	for miniframe in miniframes:
		if not is_instance_valid(miniframe):
			miniframes.erase(miniframe)
