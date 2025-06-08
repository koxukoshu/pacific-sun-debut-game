extends Control

@onready var button_click: AudioStreamPlayer = $ButtonClick

func _on_start_pressed() -> void:
	button_click.play()
	var timer = get_tree().create_timer(0.4)
	await timer.timeout 
	get_tree().change_scene_to_file("res://game.tscn")
