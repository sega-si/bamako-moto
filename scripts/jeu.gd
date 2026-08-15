extends Node2D

## La partie : la route qui defile, les obstacles qui arrivent, le score.
##
## Tout ce qui monte avec le temps est regroupe ici, pour qu'on puisse
## regler la difficulte a un seul endroit.

const OBSTACLE := preload("res://scenes/obstacle.tscn")

## Vitesse de defilement au demarrage, en pixels par seconde.
@export var vitesse_depart: float = 520.0

## Ce que la vitesse gagne par seconde de survie. C'est ce chiffre qui
## decide si la partie devient tendue au bout d'une minute ou de cinq.
@export var acceleration: float = 14.0

@export var vitesse_maximale: float = 1500.0

## Bornes de l'intervalle entre deux apparitions, en secondes. Il se
## resserre a mesure que la vitesse monte.
@export var intervalle_depart: float = 1.15
@export var intervalle_minimal: float = 0.42

var vitesse: float = 0.0
var score: float = 0.0
var en_cours: bool = true

var _depuis_derniere_apparition: float = 0.0
var _prochain_intervalle: float = 1.0
var _derniere_voie: int = -1

@onready var _route: Sprite2D = $Route
@onready var _moto = $Moto
@onready var _obstacles: Node2D = $Obstacles
@onready var _score: Label = $Interface/Score
@onready var _fin: VBoxContainer = $Interface/Fin
@onready var _score_final: Label = $Interface/Fin/ScoreFinal


func _ready() -> void:
	vitesse = vitesse_depart
	_prochain_intervalle = intervalle_depart
	_fin.hide()
	_moto.touchee.connect(_terminer)


func _process(delta: float) -> void:
	if not en_cours:
		if Input.is_action_just_pressed("rejouer"):
			get_tree().reload_current_scene()
		return

	vitesse = minf(vitesse + acceleration * delta, vitesse_maximale)

	# Le defilement de la route se fait en decalant la fenetre de lecture
	# de la texture, pas en deplacant des objets. Un seul noeud suffit, et
	# le raccord est invisible parce que la tuile se repete exactement.
	_route.region_rect.position.y -= vitesse * delta

	score += vitesse * delta * 0.01
	_score.text = "%d m" % int(score)

	_depuis_derniere_apparition += delta
	if _depuis_derniere_apparition >= _prochain_intervalle:
		_depuis_derniere_apparition = 0.0
		_faire_apparaitre()
		# L'intervalle suit la vitesse : plus on va vite, plus les
		# vehicules se rapprochent, sinon la route se viderait.
		var avancement := (vitesse - vitesse_depart) / (vitesse_maximale - vitesse_depart)
		_prochain_intervalle = lerpf(intervalle_depart, intervalle_minimal, avancement)
		_prochain_intervalle *= randf_range(0.85, 1.15)


func _faire_apparaitre() -> void:
	var voie := randi() % 3
	# Jamais deux fois la meme voie d'affilee : sinon le joueur n'a rien a
	# faire, il lui suffit de rester sur le cote.
	if voie == _derniere_voie:
		voie = (voie + 1 + randi() % 2) % 3
	_derniere_voie = voie

	var obstacle := OBSTACLE.instantiate()
	_obstacles.add_child(obstacle)
	obstacle.configurer(obstacle.MODELES[randi() % obstacle.MODELES.size()])

	# Trois voies entre les lignes de rive, obstacle au centre de la sienne.
	const BORD := 64.0
	var largeur_voie := (get_viewport_rect().size.x - BORD * 2.0) / 3.0
	obstacle.position = Vector2(
			BORD + largeur_voie * (float(voie) + 0.5),
			-260.0)
	obstacle.vitesse = vitesse


func _terminer() -> void:
	if not en_cours:
		return
	en_cours = false
	_score_final.text = "%d mètres" % int(score)
	_fin.show()
	# Les obstacles deja a l'ecran s'immobilisent : la partie est finie,
	# plus rien ne doit bouger derriere le panneau.
	for obstacle in _obstacles.get_children():
		obstacle.set_process(false)
	_moto.set_process(false)
