extends Node

## Capture l'ecran du garage, pour verifier la mise en page sans avoir a
## lancer le jeu a la main.

## Capture chaque vehicule du catalogue, pour les voir tous d'un coup.

func _ready() -> void:
	Donnees.pieces = 9999
	for m in Catalogue.MOTOS:
		if str(m["cle"]) not in Donnees.motos_possedees:
			Donnees.motos_possedees.append(str(m["cle"]))

	for i in range(Catalogue.MOTOS.size()):
		Donnees.moto_choisie = str(Catalogue.MOTOS[i]["cle"])
		var garage := load("res://scenes/garage.tscn").instantiate()
		add_child(garage)
		await get_tree().create_timer(0.9).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(
				"res://outils/garage_%d.png" % i)
		print("capture %d : %s" % [i, Catalogue.MOTOS[i]["nom"]])
		garage.queue_free()
		await get_tree().process_frame
	get_tree().quit()
