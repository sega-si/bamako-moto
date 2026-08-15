extends Area2D

## Un vehicule ou un trou qui descend vers le joueur.
##
## L'obstacle ne sait rien du jeu : il descend, et il se supprime quand il
## sort de l'ecran. C'est la scene de jeu qui decide quand en faire naitre
## un, et lequel.

## Vitesse de descente, en pixels par seconde. La scene de jeu l'augmente
## au fil de la partie.
var vitesse: float = 600.0

@onready var _image: Sprite2D = $Image
@onready var _forme: CollisionShape2D = $Forme


## Les obstacles possibles. « occupe » dit quelle part de la largeur de la
## route le vehicule prend, ce qui sert a ne pas boucher les trois voies
## d'un coup et rendre la partie injouable.
const MODELES := [
	{"image": "res://art/sotrama.png", "occupe": 0.30},
	{"image": "res://art/taxi.png", "occupe": 0.26},
	{"image": "res://art/nid_de_poule.png", "occupe": 0.22},
]


func configurer(modele: Dictionary) -> void:
	var texture: Texture2D = load(modele["image"])
	_image.texture = texture

	# La forme de collision est un peu plus petite que l'image. Un joueur
	# qui frole un sotrama et voit « touche » trouve le jeu injuste ; on
	# lui laisse quelques pixels de pardon.
	var forme := RectangleShape2D.new()
	forme.size = texture.get_size() * 0.82
	_forme.shape = forme


func _process(delta: float) -> void:
	position.y += vitesse * delta
	# Une fois bien sorti par le bas, l'obstacle n'a plus aucune raison
	# d'exister : le garder couterait de la memoire pour rien.
	if position.y > get_viewport_rect().size.y + 300.0:
		queue_free()
