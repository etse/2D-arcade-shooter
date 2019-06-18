extends KinematicBody2D

var fireBullet = preload("res://components/Bullets/FireBullet/FireBullet.tscn") 
const acceleration_force = 9000
const dampening = 10
const max_speed = 2700
var velocity = Vector2(0, 0)
var acceleration = Vector2(0,0 );
var gun_cooldown = 0

func _ready():
	$Exhaust1.play();
	$Exhaust2.play();	

func _physics_process(delta: float):
	velocity = velocity - (velocity * dampening * delta)
		
	velocity = velocity + (acceleration * delta)
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	velocity = move_and_slide(velocity)
	
	handle_shooting(delta)
	
func _input(event: InputEvent):
	handle_movement(event)
	
func handle_shooting(delta: float):
	if gun_cooldown > 0:
		gun_cooldown -= delta
	
	if Input.is_action_pressed("shoot") && gun_cooldown <= 0:
		var bulletLeft = fireBullet.instance()
		var bulletRight = fireBullet.instance()
		bulletLeft.position = get_global_transform().xform($LeftGun.position)
		bulletRight.position = get_global_transform().xform($RightGun.position)
		$Bullets.add_child(bulletLeft)
		$Bullets.add_child(bulletRight)
		gun_cooldown = 0.4
	
func handle_movement(event: InputEvent):
	if event.is_action("move_left"):
		if event.is_pressed():
			acceleration.x = -acceleration_force
		elif acceleration.x < 0:
			acceleration.x = 0;
	if event.is_action("move_right"):
		if event.is_pressed():
			acceleration.x = acceleration_force
		elif acceleration.x > 0:
			acceleration.x = 0;
			
	if event.is_action("move_up"):
		if event.is_pressed():
			acceleration.y = -acceleration_force
		elif acceleration.y < 0:
			acceleration.y = 0;
	if event.is_action("move_down"):
		if event.is_pressed():
			acceleration.y = acceleration_force
		elif acceleration.y > 0:
			acceleration.y = 0;
	