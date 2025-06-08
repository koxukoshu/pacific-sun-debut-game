extends Node

@onready var game_over: Control = $GameOver
@onready var play_again: Button = $GameOver/PlayAgain
@onready var toy: RigidBody2D = $toy  
@onready var character: Sprite2D = $character


func _ready() -> void:
	game_over.visible = false


func _process(delta: float):
	var direction_to_toy = (toy.global_position - character.global_position).normalized()
	character.rotation = direction_to_toy.angle() + 1.5708 * 2
	
func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func trigger_game_over():
	print("Game Over triggered")
	game_over.visible = true


func _on_toy_body_entered(body: Node) -> void:
	trigger_game_over()
