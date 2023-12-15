extends CharacterBody2D

var fireBullet = preload("res://components/Bullets/FireBullet/FireBullet.tscn") 
const acceleration_force = 7000
const dampening = 10
const max_speed = 1000
const max_speed_shooting = 500
var acceleration = Vector2(0,0);
var gun_cooldown = 0
var isDestroyed = false
var max_health = 100
var health = 100
var health_regen = 5

signal health_changed
signal destroyed

func _ready():
	$Exhaust1.play();
	$Exhaust2.play();	

func _physics_process(delta: float):
	if acceleration.length() > 0:
		velocity = velocity + (acceleration * delta)
	else:
		velocity = velocity - (velocity * dampening * delta)
		
	var velocity_max = max_speed_shooting if Input.is_action_pressed("shoot") else max_speed
	if velocity.length() > velocity_max:
		velocity = velocity.normalized() * velocity_max
	
	handle_collision(delta)
	set_velocity(velocity)
	move_and_slide()
	velocity = velocity
	handle_shooting(delta)
	
func _input(event: InputEvent):
	handle_movement(event)
	
func handle_collision(delta):
	for collider in $CollisionArea.get_overlapping_areas():
		if collider.is_in_group("enemies") and not collider.is_in_group("bullets"):
			collider.on_hit(2)
			self.on_hit(15)
			self.velocity = (self.position - collider.position).normalized() * 600
	
func handle_shooting(delta: float):
	if gun_cooldown > 0:
		gun_cooldown -= delta
	
	if Input.is_action_pressed("shoot") && gun_cooldown <= 0:
		var bulletLeft = fireBullet.instantiate()
		var bulletRight = fireBullet.instantiate()
		bulletLeft.position = get_global_transform() * ($LeftGun.position)
		bulletRight.position = get_global_transform() * ($RightGun.position)
		$Bullets.add_child(bulletLeft)
		$Bullets.add_child(bulletRight)
		$BulletSound.play()
		gun_cooldown = 0.4
		
func on_hit(damage: float):
	health -= damage
	$AnimationPlayer.play("hit")
	if self.health <= 0 and not self.isDestroyed:
		self.on_destroyed()
	
func on_destroyed():
	self.isDestroyed = true
	$CollisionShape2D.disabled = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.plat()
	CameraControl.screen_shake(22, 10, 0.5)
	destroyed.emit()
	
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
			
func _update_health(health_change: float):
	if self.health < self.max_health:
		if self.health + health_change >= self.max_health:
			self.health = self.max_health
		else:
			self.health = self.health + health_change
		health_changed.emit(self.health)
	

func _on_HealthRegenTimer_timeout():
	var regen = self.health_regen / 10.0 if Input.is_action_pressed("shoot") else self.health_regen
	self._update_health(regen * $HealthRegenTimer.wait_time)
