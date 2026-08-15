extends Node

## Outil de developpement : lance la partie, laisse quelques secondes a
## l'avenue pour se remplir, enregistre une image et un releve de vitesse,
## puis quitte.
##
## Rien ici ne part dans le jeu publie.

const SECONDES := 6.0
const SORTIE := "res://outils/apercu.png"

var _releve: Array[float] = []
var _temps := 0.0


func _ready() -> void:
	add_child(load("res://scenes/jeu.tscn").instantiate())


func _process(delta: float) -> void:
	_temps += delta
	# La premiere seconde contient la compilation des nuanceurs : elle
	# n'a lieu qu'une fois et fausserait la mesure.
	if _temps > 1.0 and delta > 0.0:
		_releve.append(1.0 / delta)

	if _temps < SECONDES:
		return
	set_process(false)

	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SORTIE)

	_releve.sort()
	var somme := 0.0
	for v in _releve:
		somme += v
	print("images par seconde — moyenne %.0f, median %.0f, plancher %.0f"
			% [somme / float(_releve.size()),
			_releve[_releve.size() / 2], _releve[0]])
	print("triangles : ", RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	print("appels de rendu : ", RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()
