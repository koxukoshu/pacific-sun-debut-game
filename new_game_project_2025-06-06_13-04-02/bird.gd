# CharacterMovingObject.gd (No changes from previous version)
extends CharacterBody2D

@export var move_speed: float = 300.0
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

signal movement_reached_target

func start_moving_to_target(target: Vector2):
	target_position = target
	is_moving = true
	print("CharacterMovingObject: Starting move to: ", target_position)

func _physics_process(delta):
	if is_moving:
		var direction_to_target = (target_position - global_position).normalized()
		velocity = direction_to_target * move_speed

		move_and_slide()

		if global_position.distance_squared_to(target_position) < (move_speed * delta * 2) ** 2:
			global_position = target_position
			velocity = Vector2.ZERO
			is_moving = false
			print("CharacterMovingObject: Reached target!")
			emit_signal("movement_reached_target")

	else:
		velocity = Vector2.ZERO
