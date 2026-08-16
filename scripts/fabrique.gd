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


## Une charrette tiree par un ane : lente, large, et elle vient de nulle
## part. C'est l'obstacle qui fait perdre les joueurs trop confiants.
static func charrette() -> Node3D:
	var n := Node3D.new()
	_poser(n, Vector3(2.1, 0.3, 2.8), Color(0.55, 0.38, 0.22),
			Vector3(0.0, 0.75, 0.0))
	for cote in [-1.0, 1.0]:
		_poser(n, Vector3(0.14, 0.5, 2.8), Color(0.45, 0.30, 0.17),
				Vector3(cote * 1.0, 1.05, 0.0))
	# Le chargement : des sacs empiles, jamais deux fois pareil.
	for i in range(3):
		var h := 0.4 + float(i % 2) * 0.2
		_poser(n, Vector3(0.7, h, 0.7), Color(0.86, 0.80, 0.62),
				Vector3(-0.55 + float(i) * 0.55, 0.9 + h * 0.5, 0.3))
	roues(n, 1.05, 0.9, 0.42)
	var ane := Node3D.new()
	_poser(ane, Vector3(0.7, 0.8, 1.6), Color(0.52, 0.47, 0.42),
			Vector3(0.0, 0.9, 0.0))
	_poser(ane, Vector3(0.45, 0.45, 0.6), Color(0.48, 0.43, 0.38),
			Vector3(0.0, 1.15, -1.0))
	ane.position = Vector3(0.0, 0.0, -2.4)
	n.add_child(ane)
	return n


## Une piece a ramasser. Elle tourne sur elle-meme : c'est ce qui la fait
## remarquer du coin de l'oeil.
static func piece() -> Node3D:
	var n := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.80, 0.15)
	m.roughness = 0.35
	m.metallic = 0.7
	m.emission_enabled = true
	m.emission = Color(0.9, 0.65, 0.1)
	m.emission_energy_multiplier = 0.35

	var maillage := CylinderMesh.new()
	maillage.top_radius = 0.42
	maillage.bottom_radius = 0.42
	maillage.height = 0.1
	maillage.radial_segments = 10
	maillage.rings = 0

	var noeud := MeshInstance3D.new()
	noeud.mesh = maillage
	noeud.material_override = m
	noeud.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	noeud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(noeud)
	return n


static func arbre(graine: int) -> Node3D:
	var n := Node3D.new()
	var hauteur := 2.4 + float(graine % 3) * 0.7
	_poser(n, Vector3(0.4, hauteur, 0.4), Color(0.40, 0.30, 0.20),
			Vector3(0.0, hauteur * 0.5, 0.0))
	var verts := [Color(0.24, 0.45, 0.20), Color(0.30, 0.52, 0.24),
			Color(0.20, 0.40, 0.18)]
	var teinte: Color = verts[graine % verts.size()]
	_poser(n, Vector3(3.0, 1.4, 3.0), teinte,
			Vector3(0.0, hauteur + 0.5, 0.0))
	_poser(n, Vector3(2.0, 1.0, 2.0), teinte.lightened(0.08),
			Vector3(0.3, hauteur + 1.4, -0.2))
	return n


## Un etal de marche avec son parasol. C'est ce qui donne l'impression
## qu'il y a des gens au bord de l'avenue.
static func etal(graine: int) -> Node3D:
	var n := Node3D.new()
	_poser(n, Vector3(2.4, 0.15, 1.4), Color(0.60, 0.44, 0.28),
			Vector3(0.0, 0.9, 0.0))
	for cote in [-1.0, 1.0]:
		_poser(n, Vector3(0.12, 0.9, 0.12), Color(0.45, 0.33, 0.22),
				Vector3(cote * 1.0, 0.45, 0.0))
	_poser(n, Vector3(0.1, 1.3, 0.1), Color(0.35, 0.35, 0.38),
			Vector3(0.0, 1.6, 0.0))
	var couleurs := [Color(0.85, 0.25, 0.22), Color(0.20, 0.45, 0.75),
			Color(0.95, 0.70, 0.15), Color(0.30, 0.60, 0.35)]
	_poser(n, Vector3(3.0, 0.16, 2.2), couleurs[graine % couleurs.size()],
			Vector3(0.0, 2.3, 0.0))
	# La marchandise, en petits tas de couleur.
	for i in range(3):
		_poser(n, Vector3(0.5, 0.3, 0.5),
				couleurs[(graine + i + 1) % couleurs.size()],
				Vector3(-0.7 + float(i) * 0.7, 1.12, 0.0))
	return n


## Un immeuble bas, avec auvent et enseigne. Quatre reglages suffisent a
## ce qu'aucun ne ressemble tout a fait au precedent.
static func immeuble(graine: int) -> Node3D:
	var n := Node3D.new()
	var murs := [Color(0.85, 0.72, 0.52), Color(0.78, 0.62, 0.46),
			Color(0.88, 0.80, 0.62), Color(0.72, 0.58, 0.44),
			Color(0.80, 0.70, 0.58), Color(0.68, 0.62, 0.52)]
	var hauteur := 3.0 + float(graine % 5) * 1.2
	var largeur := 4.0 + float(graine % 3) * 1.2

	_poser(n, Vector3(largeur, hauteur, 6.0), murs[graine % murs.size()],
			Vector3(0.0, hauteur * 0.5, 0.0))
	_poser(n, Vector3(largeur + 0.4, 0.3, 6.4), Color(0.60, 0.54, 0.46),
			Vector3(0.0, hauteur + 0.15, 0.0))

	# Un etage en retrait, une fois sur trois : c'est ce qui casse
	# l'alignement des toits et empeche la rue d'avoir l'air d'un couloir.
	if graine % 3 == 0:
		var h2 := 2.2
		_poser(n, Vector3(largeur * 0.7, h2, 4.0),
				murs[(graine + 2) % murs.size()],
				Vector3(0.0, hauteur + h2 * 0.5 + 0.3, -0.6))

	# Auvent et enseigne cote rue.
	var enseignes := [Color(0.88, 0.22, 0.20), Color(0.20, 0.50, 0.80),
			Color(0.95, 0.72, 0.12), Color(0.25, 0.62, 0.38)]
	_poser(n, Vector3(0.2, 0.9, 4.0), enseignes[graine % enseignes.size()],
			Vector3(-largeur * 0.5 - 0.1, 2.4, 0.0))
	if graine % 2 == 0:
		_poser(n, Vector3(1.6, 0.12, 4.4), Color(0.35, 0.35, 0.38),
				Vector3(-largeur * 0.5 - 0.8, 2.9, 0.0))
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
