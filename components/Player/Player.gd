extends RigidBody2D

const acceleration = 4200
var velocity = Vector2(0, 0)
var desired_x_velocity = 0;
var desired_y_velocity = 0;

func _ready():
	$Exhaust1.play();
	$Exhaust2.play();	

func _physics_process(delta: float):
	velocity.x = desired_x_velocity
	velocity.y = desired_y_velocity
	applied_force = velocity	
	
func _input(event: InputEvent):
	handle_movement(event)	
	
func handle_movement(event: InputEvent):
	if event.is_action("move_left"):
		if event.is_pressed():
			desired_x_velocity = -acceleration
		elif desired_x_velocity < 0:
			desired_x_velocity = 0;
	if event.is_action("move_right"):
		if event.is_pressed():
			desired_x_velocity = acceleration
		elif desired_x_velocity > 0:
			desired_x_velocity = 0;
			
	if event.is_action("move_up"):
		if event.is_pressed():
			desired_y_velocity = -acceleration
		elif desired_y_velocity < 0:
			desired_y_velocity = 0;
	if event.is_action("move_down"):
		if event.is_pressed():
			desired_y_velocity = acceleration
		elif desired_y_velocity > 0:
			desired_y_velocity = 0;
	