extends Sprite2D 


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var kick_area: Area2D = $KickArea 
@onready var kick_sfx: AudioStreamPlayer2D = $kick_sfx

var is_kicking = false

func _ready() -> void:
	# Hide the system mouse cursor if you want your sprite to be the only cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Connect the kick area's signal to handle hits
	kick_area.connect("body_entered", _on_kick_area_body_entered)
	kick_area.monitoring = false # Start with kick hitbox off

func _process(delta: float) -> void:
	# Directly set the sprite's position to the mouse's global position
	global_position = get_global_mouse_position()

	# Handle kick input
	if Input.is_action_just_pressed("kick") and not is_kicking:
		_do_kick()

	if not is_kicking:
		animated_sprite_2d.play("default")

# Initiates the kick attack
func _do_kick() -> void:
	is_kicking = true
	animated_sprite_2d.play("kicking")
	kick_area.monitoring = true # Enable the hitbox for the kick

	# Wait for a short duration, then disable the hitbox and end the kick
	await get_tree().create_timer(0.3).timeout
	kick_area.monitoring = false
	is_kicking = false

# Called when the kick area detects a body
func _on_kick_area_body_entered(body: Node) -> void:
	if is_kicking == true: # Ensure the kick is active
		if body is RigidBody2D: # Only affect RigidBody2D nodes
			kick_sfx.play()
			print("Kicked: ", body.name)

			var base_vertical_kick_strength = 800.0   # Base strength for the upward kick
			var base_horizontal_kick_strength = 200.0 # Base strength for the horizontal kick

			var body_vertical_velocity = body.linear_velocity.y
			var final_vertical_impulse_strength: float
			var final_horizontal_impulse_strength: float

			# --- Calculate Vertical Impulse Strength ---
			# Weakens kick if body is already moving fast upwards
			if body_vertical_velocity < -200: # Body is moving upwards relatively fast (negative Y is up)
				final_vertical_impulse_strength = max(200.0, base_vertical_kick_strength + body_vertical_velocity * 0.5)
			# Strengthens kick if body is moving fast downwards
			elif body_vertical_velocity > 200: # Body is moving downwards relatively fast (positive Y is down)
				final_vertical_impulse_strength = base_vertical_kick_strength + abs(body_vertical_velocity) * 0.5
			# Default kick strength for slow or neutral vertical movement
			else:
				final_vertical_impulse_strength = base_vertical_kick_strength

			# --- Retrieve the body's radius from its CollisionShape2D ---
			var body_radius: float = 0.0
			# Attempt to get the CollisionShape2D child. It's common to name it "CollisionShape2D".
			var collision_shape_node = body.get_node_or_null("CollisionShape2D")

			if collision_shape_node and collision_shape_node.shape is CircleShape2D:
				# If found and it's a CircleShape2D, get its radius
				var circle_shape: CircleShape2D = collision_shape_node.shape
				body_radius = circle_shape.radius
			else:
				body_radius = 50.0 # Default radius, adjust this if 50 is too large/small for your game

			# Ensure body_radius is not zero or negative to prevent division by zero errors
			if body_radius <= 0.0:
				body_radius = 1.0 # Set a minimum valid radius

			# Calculate the relative hit position from the body's center
			# `relative_hit_x` is negative if kick_area is left, positive if right of body's center
			var relative_hit_x = kick_area.global_position.x - body.global_position.x
			# `relative_hit_y` is negative if kick_area is above, positive if below body's center
			var relative_hit_y = kick_area.global_position.y - body.global_position.y

			# --- Horizontal Impulse Direction & Magnitude ---
			var impulse_direction_x: float = 0.0

			# If hit to the right of the body, push to the left (-X)
			if relative_hit_x > 0:
				impulse_direction_x = -1.0
			# If hit to the left of the body, push to the right (+X)
			elif relative_hit_x < 0:
				impulse_direction_x = 1.0
			# If hit perfectly in the center X, impulse_direction_x remains 0, no horizontal push.

			# The magnitude of horizontal impulse scales with how far from the center it was hit horizontally.
			# Normalize `relative_hit_x` by the body's radius.
			var horizontal_offset_factor = abs(relative_hit_x) / (body_radius + 1.0) # Add 1.0 to avoid division by very small numbers
			# Clamp to prevent extreme values.
			horizontal_offset_factor = clamp(horizontal_offset_factor, 0.0, 1.5) # Max 1.5x base strength (can be adjusted)

			final_horizontal_impulse_strength = base_horizontal_kick_strength * horizontal_offset_factor * impulse_direction_x

			# --- Adjust Horizontal Impulse based on Vertical Hit Position ---
			# If hit on the lower half of the body (relative_hit_y > 0), reduce horizontal impulse.
			var vertical_dampening_factor = 1.0
			if relative_hit_y > 0: # If the kick hits below the body's vertical center
				# Calculate a factor based on how far down it was hit (normalized by body_radius).
				var y_offset_from_center_factor = relative_hit_y / (body_radius + 1.0)
				y_offset_from_center_factor = clamp(y_offset_from_center_factor, 0.0, 1.0) # From 0 (center) to 1 (bottom edge)

				# Reduce horizontal impulse by up to 50% (0.5 multiplier) if hit at the very bottom.
				vertical_dampening_factor = 1.0 - (y_offset_from_center_factor * 0.5)
				# Ensure the horizontal impulse is not reduced below 50% of its calculated value.
				vertical_dampening_factor = max(0.5, vertical_dampening_factor) # Minimum 50% strength retained

			final_horizontal_impulse_strength *= vertical_dampening_factor

			body.apply_central_impulse(Vector2(final_horizontal_impulse_strength, -final_vertical_impulse_strength))
