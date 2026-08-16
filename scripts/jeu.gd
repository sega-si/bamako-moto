extends Node3D

## La partie : l'avenue qui remonte, la circulation, les pieces, le score.
##
## Tout ce qui monte avec le temps est reuni ici, pour que la difficulte se
## regle a un seul endroit.

const TRONCON := preload("res://scenes/troncon.tscn")
const OBSTACLE := preload("res://scenes/obstacle.tscn")
const PIECE := preload("res://scenes/piece.tscn")

const NOMBRE_TRONCONS := 12
const LARGEUR_VOIE := 3.0
const VOIES := [-LARGEUR_VOIE, 0.0, LARGEUR_VOIE]
const DEPART_Z := -135.0

## Vitesse au demarrage, en metres par seconde. 22 m/s font environ 80 km/h.
@export var vitesse_depart: float = 22.0

## Ce que la vitesse gagne par seconde de survie.
@export var acceleration: float = 0.55

@export var vitesse_maximale: float = 58.0

## Distance entre deux vagues, en metres. Exprimee en distance et non en
## secondes : la densite reste la meme quand on accelere, au lieu de
## devenir infernale.
@export var espacement_depart: float = 40.0
@export var espacement_minimal: float = 20.0

## Un frolement compte quand on passe a moins de cette distance du bord
## d'un vehicule, sans le toucher.
@export var distance_frolement: float = 1.6

var vitesse: float = 0.0
var distance: float = 0.0
var pieces: int = 0
var en_cours: bool = true

var _troncons: Array[Node3D] = []
var _prochaine_apparition: float = 25.0
var _prochaine_piece: float = 45.0
var _derniere_voie: int = -1
var _secousse: float = 0.0
var _combo: int = 0
var _combo_restant: float = 0.0
var _bonus: float = 0.0

@onready var _moto: Area3D = $Moto
@onready var _obstacles: Node3D = $Obstacles
@onready var _camera: Camera3D = $Camera
@onready var _score: Label = $Interface/Score
@onready var _compteur_pieces: Label = $Interface/Pieces
@onready var _annonce: Label = $Interface/Annonce
@onready var _fin: VBoxContainer = $Interface/Fin
@onready var _score_final: Label = $Interface/Fin/ScoreFinal
@onready var _record: Label = $Interface/Fin/Record

const FICHIER := "user://partie.cfg"


func _ready() -> void:
	vitesse = vitesse_depart
	_fin.hide()
	_annonce.modulate.a = 0.0
	_moto.touchee.connect(_terminer)

	for i in range(NOMBRE_TRONCONS):
		var t := TRONCON.instantiate()
		add_child(t)
		t.construire(i)
		t.position.z = 10.0 - float(i) * 20.0
		_troncons.append(t)


func _process(delta: float) -> void:
	if not en_cours:
		if Input.is_action_just_pressed("rejouer"):
			get_tree().reload_current_scene()
		_animer_camera(delta)
		return

	vitesse = minf(vitesse + acceleration * delta, vitesse_maximale)
	var avance := vitesse * delta
	distance += avance

	_faire_defiler(avance)
	_gerer_apparitions()
	_gerer_frolements()
	_gerer_combo(delta)
	_animer_camera(delta)

	_score.text = "%d m" % int(distance + _bonus)
	_compteur_pieces.text = "◉ %d" % pieces


func _faire_defiler(avance: float) -> void:
	for t in _troncons:
		t.position.z += avance
		if t.position.z > 30.0:
			t.position.z -= 20.0 * float(NOMBRE_TRONCONS)

	for o in _obstacles.get_children():
		o.vitesse_du_jeu = vitesse


func _gerer_apparitions() -> void:
	if distance >= _prochaine_piece:
		_faire_apparaitre_pieces()

	if distance < _prochaine_apparition:
		return

	var avancement := clampf(
			(vitesse - vitesse_depart) / (vitesse_maximale - vitesse_depart),
			0.0, 1.0)
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
		_faire_apparaitre(voie, voies_prises, nombre)
	_derniere_voie = voies_prises[0]


func _choisir_voie(deja_prises: Array[int]) -> int:
	var libres: Array[int] = []
	for v in range(3):
		if v not in deja_prises:
			libres.append(v)
	if deja_prises.is_empty() and libres.size() > 1 and _derniere_voie in libres:
		libres.erase(_derniere_voie)
	return libres[randi() % libres.size()]


func _faire_apparaitre(voie: int, voies_prises: Array[int], nombre: int) -> void:
	var obstacle := OBSTACLE.instantiate()
	_obstacles.add_child(obstacle)
	obstacle.construire(randi() % 4)
	obstacle.position = Vector3(VOIES[voie], 0.0, DEPART_Z)
	obstacle.vitesse_du_jeu = vitesse

	# Un vehicule sur six se rabat, mais jamais quand un autre arrive de
	# front : sinon les deux voies se ferment et la vague est imparable.
	if nombre == 1 and obstacle.vitesse_propre > 5.0 and randf() < 0.18:
		var ailleurs: Array[int] = []
		for v in range(3):
			if v != voie and v not in voies_prises:
				ailleurs.append(v)
		if not ailleurs.is_empty():
			obstacle.faire_deriver(VOIES[ailleurs[randi() % ailleurs.size()]])


func _faire_apparaitre_pieces() -> void:
	# Une file de pieces, sur une seule voie. C'est ce qui donne au joueur
	# une raison d'aller quelque part, au lieu de seulement fuir.
	var voie := randi() % 3
	var combien := 4 + randi() % 4
	for i in range(combien):
		var piece := PIECE.instantiate()
		_obstacles.add_child(piece)
		piece.position = Vector3(VOIES[voie], 1.0, DEPART_Z - float(i) * 4.5)
		piece.vitesse_du_jeu = vitesse
		piece.ramassee.connect(_sur_piece_ramassee)
	_prochaine_piece = distance + randf_range(55.0, 95.0)


func _sur_piece_ramassee(_ou: Vector3) -> void:
	pieces += 1
	_bonus += 5.0


func _gerer_frolements() -> void:
	## Passer tout pres d'un vehicule sans le toucher rapporte gros.
	##
	## Sans cela, la seule strategie sensee est de rester loin de tout, et
	## le jeu punit l'audace au lieu de la recompenser.
	for o in _obstacles.get_children():
		if not (o is Area3D) or not "frolement_compte" in o:
			continue
		if o.frolement_compte or o.position.z < 1.0:
			continue
		o.frolement_compte = true

		var demi_largeur: float = o.GABARITS[o.genre].x * 0.5
		var ecart: float = absf(o.position.x - _moto.position.x)
		if ecart < demi_largeur + distance_frolement:
			_combo += 1
			_combo_restant = 2.5
			_bonus += 10.0 * float(_combo)
			_annoncer("Frôlé !  ×%d" % _combo if _combo > 1 else "Frôlé !")


func _gerer_combo(delta: float) -> void:
	if _combo_restant > 0.0:
		_combo_restant -= delta
		if _combo_restant <= 0.0:
			_combo = 0
	_annonce.modulate.a = maxf(_annonce.modulate.a - delta * 1.6, 0.0)


func _annoncer(texte: String) -> void:
	_annonce.text = texte
	_annonce.modulate.a = 1.0


func _animer_camera(delta: float) -> void:
	var avancement := clampf(
			(vitesse - vitesse_depart) / (vitesse_maximale - vitesse_depart),
			0.0, 1.0)

	# Le champ de vision s'ouvre avec la vitesse. C'est le plus vieux truc
	# du jeu de course, et le plus efficace : on ne calcule pas la vitesse,
	# on la ressent.
	_camera.fov = lerpf(_camera.fov, 62.0 + avancement * 14.0,
			clampf(delta * 2.0, 0.0, 1.0))

	var tremblement := Vector2.ZERO
	if _secousse > 0.0:
		_secousse = maxf(_secousse - delta * 2.5, 0.0)
		tremblement = Vector2(randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)) * _secousse * 0.45

	_camera.position.x = lerpf(_camera.position.x, _moto.position.x * 0.35,
			clampf(delta * 5.0, 0.0, 1.0)) + tremblement.x
	_camera.position.y = 4.6 + tremblement.y


func _terminer() -> void:
	if not en_cours:
		return
	en_cours = false
	_secousse = 1.0
	_annonce.modulate.a = 0.0

	var total := int(distance + _bonus)
	_score_final.text = "%d points" % total

	var sauvegarde := ConfigFile.new()
	sauvegarde.load(FICHIER)
	var record := int(sauvegarde.get_value("partie", "record", 0))
	var tresor := int(sauvegarde.get_value("partie", "pieces", 0))

	if total > record:
		record = total
		_record.text = "Nouveau record !"
	else:
		_record.text = "Record : %d" % record

	sauvegarde.set_value("partie", "record", record)
	sauvegarde.set_value("partie", "pieces", tresor + pieces)
	sauvegarde.save(FICHIER)

	_fin.show()
	_moto.arreter()
	for o in _obstacles.get_children():
		o.set_process(false)
