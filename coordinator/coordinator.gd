extends Node

## Coordinator acts as a high level manager for a bunch of systems.
## For minigames, typically it acts as a replacement for SceneTree.
## Also acts as an event bus for item interactions.
##
## One of the main ideas behind Coordinator is that you should be able to
## call the replacement methods (such as current_scene) without any checks.
## These methods should all work regardless of whether the caller node is in
## the collage scene or in its own scene. 
## This way, we can preserve the notion that all scenes should be playable
## by themselves.
## There is [method get_collage] and [method is_collage] as fallbacks,
## but most games shouldn't need to call them. 

## Emitted when a minigame was clicked. 
## Provides the miniframe object around the minigame that was clicked.
signal miniframe_clicked(miniframe: Miniframe)

## Emitted when any slot is interacted with anywhere.
## Provides the click event, the slot that was clicked, and the main root
## of slot that was interacted with. Make sure to check that the [param root]
## is equal to Coordinator.get_root(self) so as to not get events
## from other minigames.
signal slot_interacted(event: InputEvent, slot: ItemSlot, root: Node)

## Inventory for the Collage scene.
## It's stored here because some minigames may want to put something in the
## collage inventory. 
@export var inventory: ArrayInventory

var miniframes: Array[Miniframe] = []:
	set(value):
		push_error("Attempted to set value of miniframes field in Coordinator directly!")

## Returns the Collage node if the main scene is the Collage scene.
func get_collage() -> Collage:
	var scene_root = get_tree().current_scene
	return scene_root as Collage # The as keyword returns null if the cast fails.

## Returns true if the main scene is collage scene, false otherwise.
func in_collage() -> bool:
	return is_instance_valid(get_collage())
	
## Gets the miniframe that is an ancestor of [param node].
## If [param node] is not a descendant of a miniframe, null will be returned.
func get_miniframe_of(node: Node) -> Miniframe:
	for miniframe in miniframes:
		if miniframe.is_ancestor_of(node):
			return miniframe
			
	return null

## Gets the local minigame root for the node given.
## For consistency with the get_root method from [class SceneTree], 
## the "root" is the node right above the root node of scene. 
## If the root node of the scene is needed, use [method current_scene] instead
## For most nodes, proper usage is [code]MinigameManager.get_root(self)[/code]
## Returns the global root if running from outside the collage scene.
## Returns the global root if called outside of any minigames but still inside the Collage.
func get_root(node: Node) -> Node:
	# This is to allow games to run in their own independent scenes for testing.
	if not in_collage():
		return get_tree().root
	
	# Normal case	
	var miniframe = get_miniframe_of(node)
	if is_instance_valid(miniframe):
		return miniframe.viewport
	return get_tree().root

## Gets the scene root of the node given. Meant to replace get_tree().current_scene.
##
## Normal usage is Coordinator.current_scene(self).
## Returns the global scene root if running from outside the collage scene.
## Returns the global scnee root if called outside of any minigames but still inside the Collage.
func current_scene(node: Node) -> Node:
	# This is to allow games to run in their own independent scenes for testing.
	if not in_collage():
		return get_tree().current_scene
		
	# Normal case	
	var miniframe = get_miniframe_of(node)
	if is_instance_valid(miniframe):
		return miniframe.scene_root
	return get_tree().current_scene
	
## Reloads the current scene. Meant to replace get_tree().reload_current_scene().
##
## Normal usage is Coordinator.reload_current_scene(self).
func reload_current_scene(node: Node) -> void:
	if not in_collage():
		# Reload current scene can return errors.
		# Might be worth figuring the exact behavior of that.
		# Until then, not worth the extra complexity.
		get_tree().reload_current_scene()
		
	# Normal case	
	var miniframe = get_miniframe_of(node)
	if is_instance_valid(miniframe):
		miniframe.reload_scene()
	else:
		# Node is in collage but not in a minigame.
		get_tree().reload_current_scene()

## Changes the current scene to [param scene]. Meant to replace get_tree().change_scene_to_file().
##
## Normal usage is Coordinator.change_scene_to_file(self, scene).
func change_scene_to_packed(node: Node, scene: PackedScene) -> Error:
	if not in_collage():
		return get_tree().change_scene_to_packed(scene)
		
	# Normal case
	var miniframe = get_miniframe_of(node)
	if is_instance_valid(miniframe):
		return miniframe.change_scene_to_packed(scene)
	else:
		# Node is in collage but not in a minigame.
		return get_tree().change_scene_to_packed(scene)
		
## Changes the current scene to the one given at path. Meant to replace get_tree().change_scene_to_file().
##
## Normal usage is Coordinator.change_scene_to_file(self, "res://example.tscn").
func change_scene_to_file(node: Node, path: String) -> Error:
	if not in_collage():
		return get_tree().change_scene_to_file(path)
		
	# Normal case
	var miniframe = get_miniframe_of(node)
	if is_instance_valid(miniframe):
		return miniframe.change_scene_to_file(path)
	else:
		# Node is in collage but not in a minigame.
		return get_tree().change_scene_to_file(path)
		
## Replacement for setting Input.mouse_mode.
## Normal usage is Coordinator.change_mouse_mode(self, Input.MOUSE_MODE_CAPTURED).
func change_mouse_mode(node: Node, mode: Input.MouseMode) -> void:
	if not in_collage():
		Input.mouse_mode = mode
		
	# Normal case
	var miniframe = get_miniframe_of(node)
	if is_instance_valid(miniframe):
		miniframe.mouse_mode = mode
	else:
		# Node is in collage but not in a minigame.
		Input.mouse_mode = mode
		
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
	
	var root: Node = get_root(clicked_node)
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
