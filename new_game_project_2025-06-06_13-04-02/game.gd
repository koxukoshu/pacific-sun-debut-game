extends Node2D 

@onready var game_over: Control = $GameOver
@onready var play_again: Button = $GameOver/PlayAgain
@onready var toy: RigidBody2D = $toy
@onready var character: Sprite2D = $character
@onready var bg_music_player: AudioStreamPlayer = $BgMusicPlayer
@onready var coin: Area2D = $Coin
@onready var score_sound: AudioStreamPlayer = $ScoreSound
@onready var bird: CharacterBody2D = $Bird
@onready var bird_2: CharacterBody2D = $Bird2
@onready var instructions: Sprite2D = $instructions

# Coin and Scoring System Variables
@export var coin_scene: PackedScene # Export a variable to link your Coin.tscn
@export var min_x: float = 80
@export var max_x: float = 800
@export var min_y: float = 50
@export var max_y: float = 420

# --- NEW: Character Moving Object Path Settings ---
@export var start_x_position: float = 1200.0 # Object starts off-screen left
@export var end_x_position: float = -100.0   # Object ends off-screen right (assuming viewport width ~800)
@export var min_y_path: float = 50.0        # Minimum Y for the path
@export var max_y_path: float = 420.0       # Maximum Y for the path

var current_score: int = 0
var current_coin_instance: Area2D # Hold a reference to the single coin instance

@onready var score_label: Label = $ScoreLabel
@onready var score: Label = $GameOver/score

# --- NEW: Wind Variables ---
@export var wind_strength: float = 0 # How strong the wind is
@export var wind_change_interval: float = 10.0 # How often the wind direction changes (in seconds)

var current_wind_direction: Vector2 = Vector2.ZERO # The current direction of the wind
var time_until_wind_change: float = 0.0 # Timer to track when to change direction

@onready var wind: Node2D = $Wind

var game_start = 0

func _ready() -> void:
	bird.visible = false
	bird_2.visible = false
	coin.visible = false
	
	
	get_tree().paused = false # Pause the game
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Hide mouse cursor for new game (as per previous suggestion)
	game_over.visible = false
	wind.visible = false
	bg_music_player.play()
	randomize() # Initialize random number generator
	update_score_display() # Initialize score display
	
	change_wind_direction()
	
	toy.gravity_scale = 0
	
	
func _process(delta: float):
	if game_start == 1:
		coin.visible = true
		toy.gravity_scale = 0.75
		spawn_initial_coin()
		instructions.visible = false
		game_start += 1
	var direction_to_toy = (toy.global_position - character.global_position).normalized()
	character.rotation = direction_to_toy.angle() + 1.5708 * 2

	# --- NEW: Wind Logic ---
	time_until_wind_change -= delta
	if time_until_wind_change <= 0:
		change_wind_direction() # Change direction when timer runs out

	# Apply the wind force to the toy
	# apply_central_force applies force at the center of the RigidBody2D
	toy.apply_central_force(current_wind_direction * wind_strength)
	# --- END NEW ---

# --- NEW: Function to change wind direction ---
func change_wind_direction():
	# Generate a random angle in radians (0 to 2*PI)
	var random_angle = randf_range(0, TAU) # TAU is 2 * PI, a full circle

	# Convert the angle to a normalized Vector2 direction
	current_wind_direction = Vector2.from_angle(random_angle)

	# Reset the timer for the next wind direction change
	time_until_wind_change = wind_change_interval
	
	wind.rotation = current_wind_direction.angle()
	print("Wind direction changed to: ", current_wind_direction, " (angle: ", rad_to_deg(random_angle), " degrees)")
# --- END NEW ---

func spawn_and_start_moving_object():
	
	# Random Y for the start point
	var random_start_y = randf_range(min_y_path, max_y_path)
	bird.position = Vector2(start_x_position, random_start_y) # Set its starting position

	# Random Y for the end point
	var random_end_y = randf_range(min_y_path, max_y_path)
	var target_coord = Vector2(end_x_position, random_end_y) # Set the target coordinate

	# Tell the new object to start moving to the target
	
	bird.visible = true
	bird.start_moving_to_target(target_coord)
	bird.movement_reached_target.connect(on_character_object_reached_target)
	
func spawn_and_start_moving_object2():

	# Random Y for the start point
	var random_start_y = randf_range(min_y_path, max_y_path)
	bird_2.position = Vector2(end_x_position, random_start_y) # Set its starting position

	# Random Y for the end point
	var random_end_y = randf_range(min_y_path, max_y_path)
	var target_coord = Vector2(start_x_position, random_end_y) # Set the target coordinate

	# Tell the new object to start moving to the target
	bird_2.visible = true
	bird_2.start_moving_to_target(target_coord)
	bird_2.movement_reached_target.connect(on_character_object_reached_target2)

func on_character_object_reached_target():
	spawn_and_start_moving_object()

func on_character_object_reached_target2():
	spawn_and_start_moving_object2()
	
func spawn_initial_coin():
	if coin_scene == null:
		print("Error: Coin scene not set in MainGame script!")
		return
	
	# Place the initial coin at a random position
	move_coin_to_random_position(coin)

func move_coin_to_random_position(coin: Area2D):
	var random_x = randf_range(min_x, max_x)
	var random_y = randf_range(min_y, max_y)
	coin.position = Vector2(random_x, random_y)


func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func trigger_game_over():
	print("Game Over triggered")
	game_over.visible = true
	score.text = "You got " + str(current_score) + " points!"
	bg_music_player.stop()
	if current_coin_instance:
		current_coin_instance.hide()
	get_tree().paused = true # Pause the game
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_toy_body_entered(body: Node) -> void:
	if body.is_in_group("avoid"):
		trigger_game_over()

# Coin Collection Function
func on_coin_collected():
	score_sound.play()
	current_score += 1
	update_score_display()
	print("Coin collected! Score: ", current_score)

	move_coin_to_random_position(coin)
	if current_score == 5:
		spawn_and_start_moving_object()
	if current_score == 12:
		wind_strength = 80
		wind.visible = true
	if current_score == 20:
		spawn_and_start_moving_object2()
		
func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(current_score)
	else:
		print("Error: ScoreLabel not found! Make sure it's linked in the editor.")
		

func _on_coin_body_entered(body: Node2D) -> void:
	if body.is_in_group("toy"):
		on_coin_collected()

func _on_return_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_character_kicked() -> void:
	if game_start == 2:
		pass
	game_start += 1
