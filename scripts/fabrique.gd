class_name Fabrique
extends RefCounted

## Fabrique la geometrie du jeu, en boites.
##
## Aucun logiciel de modelisation, aucun fichier a telecharger : tout sort
## d'ici. C'est l'esthetique « low poly », et c'est aussi ce qui garde
## l'application sous les vingt megaoctets.
##
## Les matieres sont mises en commun : deux boites de la meme couleur
## partagent la meme, sinon la carte graphique changerait d'etat a chaque
## objet et le nombre d'appels de rendu exploserait.

static var _matieres: Dictionary = {}


static func matiere(couleur: Color, rugosite := 0.92) -> StandardMaterial3D:
	var cle := "%s_%.2f" % [couleur.to_html(false), rugosite]
	if not _matieres.has(cle):
		var m := StandardMaterial3D.new()
		m.albedo_color = couleur
		m.roughness = rugosite
		m.metallic = 0.0
		_matieres[cle] = m
	return _matieres[cle]


static func boite(taille: Vector3, couleur: Color,
		projette_une_ombre := true) -> MeshInstance3D:
	var maillage := BoxMesh.new()
	maillage.size = taille
	var noeud := MeshInstance3D.new()
	noeud.mesh = maillage
	noeud.material_override = matiere(couleur)
	# Le calcul des ombres est une seconde passe de rendu : tout ce qui est
	# pose a plat sur le sol double son cout pour une ombre que personne ne
	# verra jamais. On la coupe sur le bitume et les bandes.
	if not projette_une_ombre:
		noeud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return noeud


static func _poser(parent: Node3D, taille: Vector3, couleur: Color,
		position: Vector3) -> MeshInstance3D:
	var n := boite(taille, couleur)
	n.position = position
	parent.add_child(n)
	return n


static func roues(parent: Node3D, ecart_x: float, ecart_z: float,
		rayon := 0.3) -> void:
	for dz in [-ecart_z, ecart_z]:
		for dx in [-ecart_x, ecart_x]:
			_poser(parent, Vector3(0.24, rayon * 2.0, rayon * 2.0),
					Color(0.09, 0.09, 0.10), Vector3(dx, rayon, dz))


## Le minibus vert et jaune. Le vehicule le plus reconnaissable de Bamako,
## et le plus gros obstacle du jeu.
static func sotrama() -> Node3D:
	var n := Node3D.new()
	_poser(n, Vector3(1.9, 2.0, 4.4), Color(0.13, 0.48, 0.25),
			Vector3(0.0, 1.2, 0.0))
	_poser(n, Vector3(1.94, 0.52, 4.44), Color(0.95, 0.86, 0.24),
			Vector3(0.0, 1.5, 0.0))
	# Pare-brise arriere : ce qu'on voit quand on le suit.
	_poser(n, Vector3(1.5, 0.7, 0.1), Color(0.55, 0.68, 0.74),
			Vector3(0.0, 1.85, 2.2))
	roues(n, 0.9, 1.4)
	return n


static func taxi() -> Node3D:
	var n := Node3D.new()
	_poser(n, Vector3(1.8, 1.0, 3.9), Color(0.93, 0.74, 0.13),
			Vector3(0.0, 0.72, 0.0))
	_poser(n, Vector3(1.6, 0.72, 2.0), Color(0.86, 0.66, 0.10),
			Vector3(0.0, 1.56, 0.2))
	_poser(n, Vector3(1.45, 0.55, 0.1), Color(0.55, 0.68, 0.74),
			Vector3(0.0, 1.6, 1.18))
	roues(n, 0.9, 1.35, 0.28)
	return n


## Un tas de sable, comme il y en a au bord de chaque chantier. Bas, donc
## moins visible que les vehicules : c'est l'obstacle qui surprend.
static func tas_de_sable() -> Node3D:
	var n := Node3D.new()
	_poser(n, Vector3(2.2, 0.5, 2.2), Color(0.74, 0.60, 0.38),
			Vector3(0.0, 0.25, 0.0))
	_poser(n, Vector3(1.4, 0.42, 1.4), Color(0.80, 0.66, 0.44),
			Vector3(0.0, 0.6, 0.0))
	return n


static func moto() -> Node3D:
	var n := Node3D.new()
	_poser(n, Vector3(0.62, 0.5, 1.9), Color(0.78, 0.16, 0.14),
			Vector3(0.0, 0.62, 0.0))
	_poser(n, Vector3(0.26, 0.62, 0.62), Color(0.10, 0.10, 0.11),
			Vector3(0.0, 0.32, -0.85))
	_poser(n, Vector3(0.26, 0.62, 0.62), Color(0.10, 0.10, 0.11),
			Vector3(0.0, 0.32, 0.85))
	_poser(n, Vector3(1.0, 0.12, 0.12), Color(0.20, 0.20, 0.22),
			Vector3(0.0, 0.98, -0.62))
	_poser(n, Vector3(0.52, 0.62, 0.42), Color(0.20, 0.32, 0.62),
			Vector3(0.0, 1.14, 0.18))
	_poser(n, Vector3(0.44, 0.42, 0.46), Color(0.94, 0.86, 0.30),
			Vector3(0.0, 1.62, 0.14))
	return n
