extends Area2D

## La moto du joueur.
##
## Elle ne monte ni ne descend : c'est la route qui defile sous elle. Le
## joueur ne fait que la deplacer de gauche a droite, au doigt sur le
## telephone, aux fleches sur l'ordinateur.

## Vitesse de deplacement lateral, en pixels par seconde.
@export var vitesse: float = 900.0

## Marge laissee de chaque cote, pour que la moto ne sorte pas du bitume.
@export var marge: float = 70.0

## Inclinaison quand elle vire, en degres. Purement visuel, mais c'est ce
## qui fait qu'une moto ressemble a une moto et pas a un rectangle.
@export var inclinaison_max: float = 18.0

signal touchee

var _largeur_ecran: float = 720.0
var _cible_x: float = 360.0
var _doigt_pose: bool = false


func _ready() -> void:
	_largeur_ecran = get_viewport_rect().size.x
	_cible_x = position.x
	area_entered.connect(_sur_collision)


func _process(delta: float) -> void:
	var precedent := position.x

	if _doigt_pose:
		# Au doigt : la moto rejoint la position touchee sans y sauter d'un
		# coup. Le facteur 12 donne un suivi vif mais pas nerveux.
		# lerpf et clampf plutot que lerp et clamp : les versions sans « f »
		# renvoient un Variant, et Godot refuse d'en deduire un type.
		position.x = lerpf(position.x, _cible_x, clampf(delta * 12.0, 0.0, 1.0))
	else:
		var direction := Input.get_axis("gauche", "droite")
		position.x += direction * vitesse * delta

	position.x = clampf(position.x, marge, _largeur_ecran - marge)

	# L'inclinaison suit le deplacement reellement effectue : elle revient
	# d'elle-meme a zero des que la moto ne bouge plus.
	var ecart := position.x - precedent
	var course := vitesse * delta if delta > 0.0 else 1.0
	var vise := clampf(ecart / course, -1.0, 1.0)
	rotation_degrees = lerpf(rotation_degrees, vise * inclinaison_max,
			clampf(delta * 10.0, 0.0, 1.0))


func _unhandled_input(evenement: InputEvent) -> void:
	# Sur telephone, un glissement se lit comme une suite d'evenements
	# tactiles. On garde le doigt en memoire pour savoir s'il est pose.
	if evenement is InputEventScreenTouch:
		_doigt_pose = evenement.pressed
		if evenement.pressed:
			_cible_x = evenement.position.x
	elif evenement is InputEventScreenDrag:
		_doigt_pose = true
		_cible_x = evenement.position.x


func _sur_collision(_autre: Area2D) -> void:
	touchee.emit()
