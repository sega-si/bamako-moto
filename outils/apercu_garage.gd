extends Node

## Capture l'ecran du garage, pour verifier la mise en page sans avoir a
## lancer le jeu a la main.

func _ready() -> void:
	add_child(load("res://scenes/garage.tscn").instantiate())
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://outils/garage.png")
	print("capture du garage ecrite")
	get_tree().quit()
