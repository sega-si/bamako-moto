extends Area3D

## Un vehicule ou un obstacle sur la chaussee.
##
## Tout ne vient pas a la meme allure, et c'est ce qui fait la difference
## entre une circulation et un mur qui avance. Un tas de sable est immobile
## et arrive donc a pleine vitesse ; un taxi roule et se laisse rattraper
## doucement, ce qui laisse le temps de le contourner.
##
## L'obstacle ne sait rien du jeu : il avance, il disparait une fois passe.

enum Genre { SOTRAMA, TAXI, CHARRETTE, SABLE }

## Vitesse du jeu, mise a jour par la partie a chaque image.
var vitesse_du_jeu: float = 20.0

## Vitesse propre du vehicule, en metres par seconde. C'est la difference
## entre les deux qui decide a quelle allure il se rapproche.
var vitesse_propre: float = 0.0

var genre: int = Genre.SOTRAMA

## Vrai une fois que la partie a compte le frolement, pour ne pas le
## compter deux fois.
var frolement_compte: bool = false

var _derive_cible: float = 0.0
var _derive_actuelle: float = 0.0

const GABARITS := {
	Genre.SOTRAMA: Vector3(1.6, 2.0, 4.0),
	Genre.TAXI: Vector3(1.5, 1.4, 3.5),
	Genre.CHARRETTE: Vector3(1.9, 1.4, 5.6),
	Genre.SABLE: Vector3(1.9, 0.7, 1.9),
}

## Allure propre de chaque genre, en metres par seconde.
const ALLURES := {
	Genre.SOTRAMA: [11.0, 17.0],
	Genre.TAXI: [15.0, 23.0],
	Genre.CHARRETTE: [2.0, 4.0],
	Genre.SABLE: [0.0, 0.0],
}


func construire(quel: int) -> void:
	genre = quel
	match genre:
		Genre.SOTRAMA:
			add_child(Fabrique.sotrama())
		Genre.TAXI:
			add_child(Fabrique.taxi())
		Genre.CHARRETTE:
			add_child(Fabrique.charrette())
		_:
			add_child(Fabrique.tas_de_sable())

	var bornes: Array = ALLURES[genre]
	vitesse_propre = randf_range(bornes[0], bornes[1])

	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	boite.size = GABARITS[genre]
	forme.shape = boite
	forme.position = Vector3(0.0, boite.size.y * 0.5, 0.0)
	add_child(forme)


## Fait dériver le vehicule sur le cote, comme un taxi qui se rabat sans
## prevenir. La partie ne l'appelle que sur les vehicules en mouvement, et
## jamais quand la voie visee est deja occupee.
func faire_deriver(vers_x: float) -> void:
	_derive_cible = vers_x - position.x


func _process(delta: float) -> void:
	var approche := vitesse_du_jeu - vitesse_propre
	position.z += approche * delta

	if not is_zero_approx(_derive_cible - _derive_actuelle):
		var pas := clampf(delta * 0.45, 0.0, 1.0)
		var avant := _derive_actuelle
		_derive_actuelle = lerpf(_derive_actuelle, _derive_cible, pas)
		position.x += _derive_actuelle - avant
		# L'inclinaison rend le rabattement lisible d'un coup d'oeil.
		rotation_degrees.y = lerpf(rotation_degrees.y,
				signf(_derive_cible) * -6.0, pas)

	if position.z > 16.0:
		queue_free()
