class_name DebugUtil
extends Object
## Library of some useful functions for writing debug modules.

## Gets the name of the [code]node[/node].
## If [code]node[/code] is invalid, returns "null" (as a string).
## If [code]full_path[/code] is true, returns the absolute path of node
## instead of just the name.
static func node_name(node: Node, full_path: bool = false) -> String:
	if not is_instance_valid(node):
		return "null"
	
	if full_path:
		return node.get_path()
	else:
		return node.name 
