extends Node3D

## La partie : l'avenue qui remonte, les vehicules qui arrivent, la camera,
## le score.
##
## Tout ce qui monte avec le temps est reuni ici, pour que la difficulte se
## regle a un seul endroit.

const TRONCON := preload("res://scenes/troncon.tscn")
const OBSTACLE := preload("res://scenes/obstacle.tscn")

const NOMBRE_TRONCONS := 12
const LARGEUR_VOIE := 3.0
const VOIES := [-LARGEUR_VOIE, 0.0, LARGEUR_VOIE]

## Vitesse au demarrage, en metres par seconde. 22 m/s font environ 80 km/h.
@export var vitesse_depart: float = 22.0

## Ce que la vitesse gagne par seconde de survie. C'est ce chiffre qui
## decide si la partie devient tendue au bout d'une minute ou de cinq.
@export var acceleration: float = 0.55

@export var vitesse_maximale: float = 58.0

## Distance entre deux vagues d'obstacles, en metres. Exprimee en distance
## et non en secondes : ainsi la densite reste la meme quand on accelere,
## au lieu de devenir infernale.
@export var espacement_depart: float = 42.0
@export var espacement_minimal: float = 21.0

var vitesse: float = 0.0
var distance: float = 0.0
var en_cours: bool = true

var _troncons: Array[Node3D] = []
var _prochaine_apparition: float = 20.0
var _derniere_voie: int = -1
var _secousse: float = 0.0

@onready var _moto: Area3D = $Moto
@onready var _obstacles: Node3D = $Obstacles
@onready var _camera: Camera3D = $Camera
@onready var _score: Label = $Interface/Score
@onready var _fin: VBoxContainer = $Interface/Fin
@onready var _score_final: Label = $Interface/Fin/ScoreFinal
@onready var _record: Label = $Interface/Fin/Record

const FICHIER_RECORD := "user://record.cfg"


func _ready() -> void:
	vitesse = vitesse_depart
	_fin.hide()
	_moto.touchee.connect(_terminer)

	for i in range(NOMBRE_TRONCONS):
		var t := TRONCON.instantiate()
		add_child(t)
		t.construire(i)
		# Le premier troncon commence sous la moto, les suivants s'alignent
		# devant elle.
		t.position.z = 10.0 - float(i) * 20.0
		_troncons.append(t)


func _process(delta: float) -> void:
	if not en_cours:
		if Input.is_action_just_pressed("rejouer"):
			get_tree().reload_current_scene()
		return

	vitesse = minf(vitesse + acceleration * delta, vitesse_maximale)
	var avance := vitesse * delta
	distance += avance

	_faire_defiler(avance)
	_gerer_apparitions()
	_animer_camera(delta)

	_score.text = "%d m" % int(distance)


func _faire_defiler(avance: float) -> void:
	for t in _troncons:
		t.position.z += avance
		# Passe derriere la camera : le troncon repart tout devant. On ne
		# cree jamais rien pendant la partie, donc jamais d'a-coup.
		if t.position.z > 30.0:
			t.position.z -= 20.0 * float(NOMBRE_TRONCONS)

	for obstacle in _obstacles.get_children():
		obstacle.vitesse = vitesse


func _gerer_apparitions() -> void:
	if distance < _prochaine_apparition:
		return

	var avancement := (vitesse - vitesse_depart) / (vitesse_maximale - vitesse_depart)
	var espacement := lerpf(espacement_depart, espacement_minimal, avancement)
	_prochaine_apparition = distance + espacement * randf_range(0.85, 1.2)

	# Au-dela de la moitie de la vitesse maximale, on ose deux vehicules de
	# front : il reste toujours une voie libre, mais il faut la trouver.
	var nombre := 1
	if avancement > 0.5 and randf() < 0.35:
		nombre = 2

	var voies_prises: Array[int] = []
	for i in range(nombre):
		var voie := _choisir_voie(voies_prises)
		voies_prises.append(voie)
		_faire_apparaitre(voie)
	_derniere_voie = voies_prises[0]


func _choisir_voie(deja_prises: Array[int]) -> int:
	var libres: Array[int] = []
	for v in range(3):
		if v not in deja_prises:
			libres.append(v)
	# Jamais deux fois de suite la meme voie quand un seul vehicule arrive :
	# sinon le joueur n'a qu'a rester sur le cote sans rien faire.
	if deja_prises.is_empty() and libres.size() > 1 and _derniere_voie in libres:
		libres.erase(_derniere_voie)
	return libres[randi() % libres.size()]


func _faire_apparaitre(voie: int) -> void:
	var obstacle := OBSTACLE.instantiate()
	_obstacles.add_child(obstacle)
	obstacle.construire(randi() % 3)
	# Juste au-dela de la portee de la brume : le vehicule sort du voile au
	# lieu d'apparaitre d'un coup, et on ne perd pas cent metres a l'attendre.
	obstacle.position = Vector3(VOIES[voie], 0.0, -135.0)
	obstacle.vitesse = vitesse


func _animer_camera(delta: float) -> void:
	var avancement := (vitesse - vitesse_depart) / (vitesse_maximale - vitesse_depart)

	# Le champ de vision s'ouvre avec la vitesse. C'est le plus vieux truc
	# du jeu de course, et le plus efficace : on ne calcule pas la vitesse,
	# on la ressent.
	_camera.fov = lerpf(_camera.fov, 62.0 + avancement * 14.0,
			clampf(delta * 2.0, 0.0, 1.0))

	# La camera suit la moto de loin, sans la coller : le decalage laisse
	# voir ou l'on va.
	var suivi := _moto.position.x * 0.35
	var tremblement := Vector3.ZERO
	if _secousse > 0.0:
		_secousse = maxf(_secousse - delta * 3.0, 0.0)
		tremblement = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0),
				0.0) * _secousse * 0.35

	_camera.position.x = lerpf(_camera.position.x, suivi,
			clampf(delta * 5.0, 0.0, 1.0)) + tremblement.x
	_camera.position.y = 4.6 + tremblement.y


func _terminer() -> void:
	if not en_cours:
		return
	en_cours = false
	_secousse = 1.0

	var metres := int(distance)
	_score_final.text = "%d mètres" % metres

	var record := _lire_record()
	if metres > record:
		record = metres
		_ecrire_record(record)
		_record.text = "Nouveau record !"
	else:
		_record.text = "Record : %d m" % record

	_fin.show()
	_moto.arreter()
	for obstacle in _obstacles.get_children():
		obstacle.set_process(false)


func _lire_record() -> int:
	var fichier := ConfigFile.new()
	if fichier.load(FICHIER_RECORD) != OK:
		return 0
	return int(fichier.get_value("partie", "record", 0))


func _ecrire_record(valeur: int) -> void:
	var fichier := ConfigFile.new()
	fichier.set_value("partie", "record", valeur)
	fichier.save(FICHIER_RECORD)
