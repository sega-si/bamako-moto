extends Area3D

## Un vehicule ou un obstacle qui remonte vers le joueur.
##
## Il ne sait rien du jeu : il avance, il disparait une fois passe. C'est
## la partie qui decide quand en faire naitre un, et lequel.

enum Genre { SOTRAMA, TAXI, SABLE }

## Vitesse de rapprochement, en metres par seconde. La partie la met a
## jour a chaque apparition.
var vitesse: float = 20.0

var genre: int = Genre.SOTRAMA


## Largeur au sol de chaque genre, pour la collision. Plus etroite que
## l'objet vu a l'ecran, toujours en faveur du joueur.
const GABARITS := {
	Genre.SOTRAMA: Vector3(1.6, 2.0, 4.0),
	Genre.TAXI: Vector3(1.5, 1.4, 3.5),
	Genre.SABLE: Vector3(1.9, 0.7, 1.9),
}


func construire(quel: int) -> void:
	genre = quel
	match genre:
		Genre.SOTRAMA:
			add_child(Fabrique.sotrama())
		Genre.TAXI:
			add_child(Fabrique.taxi())
		_:
			add_child(Fabrique.tas_de_sable())

	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = GABARITS[genre]
	forme.shape = boite
	forme.position = Vector3(0.0, boite.size.y * 0.5, 0.0)
	add_child(forme)


func _process(delta: float) -> void:
	position.z += vitesse * delta
	# Une fois derriere la camera, l'obstacle n'a plus aucune raison
	# d'exister.
	if position.z > 16.0:
		queue_free()
