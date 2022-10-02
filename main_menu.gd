extends Control

func _ready():
	Audio.get_node("AudioStreamPlayer").play()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_start_button_pressed():
	SceneManager.goto_game_scene()
