extends Area3D

## La moto du joueur.
##
## Elle n'avance pas : elle reste sur place et c'est l'avenue qui remonte
## vers elle. Le joueur ne fait que la deplacer d'une voie a l'autre, au
## doigt sur le telephone, aux fleches sur l'ordinateur.
##
## Ses caracteristiques viennent du garage : la tenue de route change sa
## vitesse laterale, et les deux couleurs sont celles que le joueur a
## choisies.

const LARGEUR_VOIE := 3.0
const VOIES := [-LARGEUR_VOIE, 0.0, LARGEUR_VOIE]

## Vitesse de deplacement lateral de base, en metres par seconde. Le
## coefficient de tenue de la moto choisie la multiplie.
@export var vitesse_laterale: float = 11.0

## Inclinaison dans les virages, en degres. Purement visuel — mais c'est
## ce qui distingue une moto d'une boite qui glisse.
@export var inclinaison_max: float = 22.0

signal touchee

var _cible_x: float = 0.0
var _doigt_pose: bool = false
var _corps: Node3D
var _poussiere: CPUParticles3D
var _invulnerable_jusqua: float = 0.0


func _ready() -> void:
	var modele := Catalogue.moto(Donnees.moto_choisie)
	vitesse_laterale *= float(modele["tenue"])

	_corps = Fabrique.moto(modele["couleur"],
			Catalogue.CASQUES[Donnees.casque_choisi]["couleur"])
	add_child(_corps)

	var forme := CollisionShape3D.new()
	var boite := BoxShape3D.new()
	# Nettement plus etroite que la moto : on pardonne au joueur qui frole.
	# Une collision ressentie comme injuste fait desinstaller un jeu.
	#
	# La Souple divise encore cette largeur par deux : c'est son pouvoir,
	# et il se joue vraiment — elle passe dans des trous ou les autres
	# accrochent.
	var largeur := 0.5
	if str(modele["pouvoir"]) == "etroite":
		largeur = 0.25
	boite.size = Vector3(largeur, 1.2, 1.5)
	forme.shape = boite
	forme.position = Vector3(0.0, 0.6, 0.0)
	add_child(forme)

	_creer_poussiere()
	area_entered.connect(_sur_choc)


func _creer_poussiere() -> void:
	# CPUParticles3D et non GPUParticles3D : le rendu « GL Compatibility »
	# ne garantit pas le second sur toutes les cartes anciennes, et a cette
	# quantite le processeur ne le sent pas.
	_poussiere = CPUParticles3D.new()
	_poussiere.amount = 24
	_poussiere.lifetime = 0.5
	_poussiere.position = Vector3(0.0, 0.15, 0.9)
	_poussiere.direction = Vector3(0.0, 0.4, 1.0)
	_poussiere.spread = 22.0
	_poussiere.initial_velocity_min = 2.0
	_poussiere.initial_velocity_max = 5.0
	_poussiere.gravity = Vector3(0.0, 1.2, 0.0)
	_poussiere.scale_amount_min = 0.06
	_poussiere.scale_amount_max = 0.15
	_poussiere.color = Color(0.74, 0.64, 0.48, 0.75)

	var grain := BoxMesh.new()
	grain.size = Vector3.ONE
	_poussiere.mesh = grain
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.68, 0.52)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_poussiere.mesh.material = m
	add_child(_poussiere)


func _sur_choc(_autre: Area3D) -> void:
	# Pendant le repit qui suit un choc encaisse, on traverse sans encaisser
	# un second coup : sinon un seul sotrama consommerait tout le blindage.
	if Time.get_ticks_msec() < _invulnerable_jusqua:
		return
	touchee.emit()


## Accorde un repit apres un choc encaisse : la moto clignote et ne peut
## plus etre touchee pendant ce temps.
func accorder_repit(secondes: float) -> void:
	_invulnerable_jusqua = Time.get_ticks_msec() + int(secondes * 1000.0)
	var clignotement := create_tween()
	clignotement.set_loops(int(secondes * 6.0))
	clignotement.tween_property(_corps, "visible", false, 0.0)
	clignotement.tween_interval(0.08)
	clignotement.tween_property(_corps, "visible", true, 0.0)
	clignotement.tween_interval(0.08)


func _process(delta: float) -> void:
	var precedent := position.x

	if _doigt_pose:
		position.x = lerpf(position.x, _cible_x, clampf(delta * 11.0, 0.0, 1.0))
	else:
		var direction := Input.get_axis("gauche", "droite")
		position.x += direction * vitesse_laterale * delta

	var bord := LARGEUR_VOIE * 1.5 - 0.5
	position.x = clampf(position.x, -bord, bord)

	# L'inclinaison suit le deplacement reellement effectue : elle revient
	# d'elle-meme a zero des que la moto cesse de se decaler.
	var course := vitesse_laterale * delta if delta > 0.0 else 1.0
	var vise := clampf((position.x - precedent) / course, -1.0, 1.0)
	_corps.rotation_degrees.z = lerpf(_corps.rotation_degrees.z,
			-vise * inclinaison_max, clampf(delta * 9.0, 0.0, 1.0))
	_corps.rotation_degrees.y = lerpf(_corps.rotation_degrees.y,
			-vise * 8.0, clampf(delta * 9.0, 0.0, 1.0))


func _unhandled_input(evenement: InputEvent) -> void:
	# Au doigt, on ne suit pas la position absolue du toucher : on convertit
	# la moitie gauche ou droite de l'ecran en voie visee, ce qui marche
	# aussi bien avec le pouce qu'avec un glissement.
	if evenement is InputEventScreenTouch:
		_doigt_pose = evenement.pressed
		if evenement.pressed:
			_viser_depuis_ecran(evenement.position.x)
	elif evenement is InputEventScreenDrag:
		_doigt_pose = true
		_viser_depuis_ecran(evenement.position.x)


func _viser_depuis_ecran(x_ecran: float) -> void:
	var largeur := get_viewport().get_visible_rect().size.x
	var part := clampf(x_ecran / largeur, 0.0, 0.999)
	_cible_x = VOIES[int(part * 3.0)]


func arreter() -> void:
	set_process(false)
	_poussiere.emitting = false
	_corps.visible = true
