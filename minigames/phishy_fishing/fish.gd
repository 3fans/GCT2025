extends Area3D

const TURN_RADIUS := 5.0

enum STATE  {
	SWIMMING,
	CAUGHT
}

var state: STATE = STATE.SWIMMING

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var time := 0.0
func _physics_process(delta: float) -> void:
	time += delta
	position = Vector3(TURN_RADIUS * cos(time), position.y, TURN_RADIUS * -sin(time))
	rotate_y(TURN_RADIUS/180*PI/PI)
	if time > 2 * PI:
		time -= 2 * PI
	pass
