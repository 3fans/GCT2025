@tool
class_name Miniframe
extends SubViewportContainer

## Miniframe is a portmanteau of "minigame frame".
## It handles the visual frame and the minigame instantiated within.
## The minigames themselves shouldn't interact with this class
## unless the minigame wants to modify the visuals of the frame.
## Use Coordinator, it's guaranteed to exist (for independent game testing)
## and it should provide enough functionality.
##
## Something to note while reading through this class:
## There are two roots. One is the SubViewport (main root) and the other
## is the root of the instantiated scene (scene root). Main root is the
## parent of scene root, don't get that confused.

## Fires whenever the miniframe is clicked. It passes itself as argument.
signal clicked(miniframe: Miniframe)

## Scale of the scene inside the viewport.
## Adjusting the scale of the container has a similar effect, but this value won't distort the frame.
@export_range(0.01, 10) var viewport_scale: float = 1
## Scene that will be rendered inside the viewport.
@export var scene: PackedScene:
	set(value):
		# @export variables call the setter before viewport is loaded
		# Await ready to make sure that viewport isn't null.
		if not is_node_ready():
			await ready
		scene = value
		reload_scene()
		
## If true, pressing the reset key will automatically reload the scene.
## Disable if the minigame handles resets manually.
@export var auto_reset: bool = true

## Root node of the instantitated minigame scene.
var scene_root: Node:
	get():
		return _scene_root
	set(value):
		push_error("Do not set root directly!")

## This reference is used for automatically resizing the frame and not for external use.
var _frame_rect: NinePatchRect = get_node_or_null("Frame") as NinePatchRect
## Reference to the root node of the instantiated scene.
## Null if scene is not instantiated.
var _scene_root: Node = null

## Easy access to the Subviewport which is acting as the main root of the minigame.
## This is not the scene root, this is the parent of the scene root.
@onready var viewport: SubViewport = $SubViewport

## True if the minigame is enabled. 
## If it is not enabled, processing will be disabled. 
var enabled: bool = false:
	set(value):
		enabled = value
		viewport.process_mode = PROCESS_MODE_INHERIT if enabled else PROCESS_MODE_DISABLED
		# TODO: This should probably save the value first. Not every scene needs object picking.
		viewport.physics_object_picking = enabled
		
func adjust_frame() -> void:
	if not is_instance_valid(_frame_rect):
		_frame_rect = get_node_or_null("Frame") as NinePatchRect
	if not is_instance_valid(_frame_rect):
		# In case the get node call is null still.
		return
		
	# Automatically adjusting frame.
	_frame_rect.position = Vector2(-_frame_rect.patch_margin_left, -_frame_rect.patch_margin_top)
	_frame_rect.size = size + Vector2(_frame_rect.patch_margin_left + _frame_rect.patch_margin_right,
			_frame_rect.patch_margin_top + _frame_rect.patch_margin_bottom)
			
func adjust_viewport() -> void:
	viewport.size_2d_override = size * viewport_scale
	
## Reloads the scene in the minigame with [member scene]
##
## Removes the scene root node of previous scene, if it exists.
## If there are any nodes that are a sibling of the root, they will remain. 
func reload_scene() -> void:
	# Remove just the root node.
	if is_instance_valid(_scene_root):
		viewport.remove_child(_scene_root)
		_scene_root.queue_free()
		
	if is_instance_valid(scene) and scene.can_instantiate():
		var new_child: Node = scene.instantiate()
		viewport.add_child(new_child)
		_scene_root = new_child

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		Coordinator.register_miniframe(self)
		reload_scene()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	adjust_frame()
	adjust_viewport()

func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
		
	if event is InputEventMouseButton:
		# Make sure the clicked signal only fires when the frame is not enabled.
		# Events need to pass down to the subviewport.
		if not enabled and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(self)
			accept_event()
	elif auto_reset and enabled and event.is_action_pressed("reset"):
		reload_scene()
		get_viewport().set_input_as_handled()
			
