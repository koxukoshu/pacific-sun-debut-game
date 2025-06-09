extends Control

@onready var button_click: AudioStreamPlayer = $ButtonClick
@onready var credits_2: Sprite2D = $credits2
@onready var bgmusic: AudioStreamPlayer = $bgmusic

func _ready() -> void:
	credits_2.visible = false
	bgmusic.play()
	
func _on_start_pressed() -> void:
	button_click.play()
	var timer = get_tree().create_timer(0.4)
	await timer.timeout 
	get_tree().change_scene_to_file("res://game.tscn")
	

func _on_credits_pressed() -> void:
	button_click.play()
	var timer = get_tree().create_timer(0.4)
	await timer.timeout 
	
	credits_2.visible = !credits_2.visible
