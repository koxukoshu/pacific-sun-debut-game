extends Sprite2D 


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var kick_area: Area2D = $KickArea 
@onready var kick_sfx: AudioStreamPlayer2D = $kick_sfx

var is_heavy_kicking = false
var is_light_kicking = false

func _ready() -> void:
	# Hide the system mouse cursor 
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Connect the kick area's signal to handle hits
	kick_area.connect("body_entered", _on_kick_area_body_entered)
	kick_area.monitoring = false # Start with kick hitbox off

func _process(delta: float) -> void:
	# Directly set the sprite's position to the mouse's global position
	global_position = get_global_mouse_position()

	# Handle kick input
	if Input.is_action_just_pressed("heavy_kick") and not is_heavy_kicking:
		_do_heavy_kick()

	if Input.is_action_just_pressed("light_kick") and not is_light_kicking:
		_do_light_kick()
		
	if not (is_heavy_kicking or is_light_kicking):
		animated_sprite_2d.play("default")

# Initiates the heavy kick attack
func _do_heavy_kick() -> void:
	is_heavy_kicking = true
	animated_sprite_2d.play("heavy_kicking")
	kick_area.monitoring = true # Enable the hitbox for the kick

	# Wait for a short duration, then disable the hitbox and end the kick
	await get_tree().create_timer(0.2).timeout
	kick_area.monitoring = false
	is_heavy_kicking = false
	
# Initiates the light kick attack
func _do_light_kick() -> void:
	is_light_kicking = true
	animated_sprite_2d.play("light_kicking")
	kick_area.monitoring = true # Enable the hitbox for the kick

	# Wait for a short duration, then disable the hitbox and end the kick
	await get_tree().create_timer(0.2).timeout
	kick_area.monitoring = false
	is_light_kicking = false
	
func _on_kick_area_body_entered(body: Node) -> void:
	if (is_heavy_kicking or is_light_kicking) and body is RigidBody2D:
		kick_sfx.play()
		print("Kicked: ", body.name)

		# --- Config ---
		var kick_speed: float = 650.0 # Constant speed after kick
		if is_light_kicking:
			kick_speed = 220.0
			
		# --- Calculate direction from hit point (kick_area) to body's center ---
		var hit_direction: Vector2 = body.global_position - kick_area.global_position

		# Normalize the direction to ensure constant speed
		var direction = hit_direction.normalized()

		# Set the final velocity
		body.linear_velocity = direction * kick_speed
	
