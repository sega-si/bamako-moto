extends Node

## Capture la meme partie a trois moments du cycle du jour.
##
## Le passage jour-nuit ne se voit pas sur une capture unique : il faut
## comparer. On triche sur la distance pour ne pas jouer vingt minutes.

const MOMENTS := [0.0, 0.55, 1.0]

var _jeu: Node3D
var _etape := 0


func _ready() -> void:
	_jeu = load("res://scenes/jeu.tscn").instantiate()
	add_child(_jeu)
	await get_tree().create_timer(2.5).timeout

	for i in range(MOMENTS.size()):
		# On avance la distance parcourue plutot que d'imposer l'heure : le
		# jeu la recalcule a chaque image, et il ecraserait tout reglage
		# pose par-dessus. On teste ainsi le vrai chemin du code.
		_jeu.distance = Ciel.DEBUT + (Ciel.FIN - Ciel.DEBUT) * MOMENTS[i]
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(
				"res://outils/heure_%d.png" % i)
		print("capture %d — avancee %.2f" % [i, MOMENTS[i]])
	get_tree().quit()
