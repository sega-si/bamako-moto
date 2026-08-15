extends Node

## Outil de developpement : lance la partie, laisse quelques secondes aux
## obstacles pour arriver a l'ecran, enregistre une image, puis quitte.
##
## Sert a montrer l'etat du jeu sans avoir a le lancer a la main. Rien ici
## ne part dans le jeu publie — ce dossier n'est jamais charge par la
## scene principale.

const SECONDES_AVANT_CAPTURE := 3.0
const SORTIE := "res://outils/apercu.png"


func _ready() -> void:
	add_child(load("res://scenes/jeu.tscn").instantiate())

	await get_tree().create_timer(SECONDES_AVANT_CAPTURE).timeout

	# Il faut attendre la fin du rendu de l'image courante, sinon on
	# capture un tampon incomplet.
	await RenderingServer.frame_post_draw

	var image := get_viewport().get_texture().get_image()
	var erreur := image.save_png(SORTIE)
	if erreur == OK:
		print("capture ecrite : ", ProjectSettings.globalize_path(SORTIE))
	else:
		push_error("echec de la capture, code %d" % erreur)

	get_tree().quit()
