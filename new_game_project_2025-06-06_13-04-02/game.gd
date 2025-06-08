extends Node2D # Changed to Node2D to easily place objects at specific positions

@onready var game_over: Control = $GameOver
@onready var play_again: Button = $GameOver/PlayAgain
@onready var toy: RigidBody2D = $toy
@onready var character: Sprite2D = $character
@onready var bg_music_player: AudioStreamPlayer = $BgMusicPlayer
@onready var coin: Area2D = $Coin
@onready var score_sound: AudioStreamPlayer = $ScoreSound
@onready var bird: CharacterBody2D = $Bird

# Coin and Scoring System Variables
@export var coin_scene: PackedScene # Export a variable to link your Coin.tscn
@export var min_x: float = 70
@export var max_x: float = 830
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

func _ready() -> void:
	game_over.visible = false
	bg_music_player.play()
	randomize() # Initialize random number generator
	update_score_display() # Initialize score display

	spawn_initial_coin()
	
	spawn_and_start_moving_object()
	
func _process(delta: float):
	var direction_to_toy = (toy.global_position - character.global_position).normalized()
	character.rotation = direction_to_toy.angle() + 1.5708 * 2


func spawn_and_start_moving_object():

	# Random Y for the start point
	var random_start_y = randf_range(min_y_path, max_y_path)
	bird.position = Vector2(start_x_position, random_start_y) # Set its starting position

	# Random Y for the end point
	var random_end_y = randf_range(min_y_path, max_y_path)
	var target_coord = Vector2(end_x_position, random_end_y) # Set the target coordinate

	# Tell the new object to start moving to the target

	bird.start_moving_to_target(target_coord)
	bird.movement_reached_target.connect(on_character_object_reached_target)

func on_character_object_reached_target():
	spawn_and_start_moving_object()

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
	get_tree().paused = false # Pause the game
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Hide mouse cursor for new game (as per previous suggestion)
	get_tree().reload_current_scene()

func trigger_game_over():
	print("Game Over triggered")
	game_over.visible = true
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

func update_score_display():
	if score_label:
		score_label.text = "Score: " + str(current_score)
	else:
		print("Error: ScoreLabel not found! Make sure it's linked in the editor.")
		

func _on_coin_body_entered(body: Node2D) -> void:
	if body.is_in_group("toy"):
		on_coin_collected()
