extends Node

@onready var game_over: Control = $GameOver
@onready var play_again: Button = $GameOver/PlayAgain
@onready var toy: RigidBody2D = $toy  # This is the instanced RigidBody2D scene

func _ready() -> void:
	game_over.visible = false

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func trigger_game_over():
	print("Game Over triggered")
	game_over.visible = true


func _on_toy_body_entered(body: Node) -> void:
	trigger_game_over()
