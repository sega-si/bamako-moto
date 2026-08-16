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


static func cylindre(rayon: float, epaisseur: float, couleur: Color,
		faces := 12, projette_une_ombre := true) -> MeshInstance3D:
	var maillage := CylinderMesh.new()
	maillage.top_radius = rayon
	maillage.bottom_radius = rayon
	maillage.height = epaisseur
	maillage.radial_segments = faces
	maillage.rings = 0
	var noeud := MeshInstance3D.new()
	noeud.mesh = maillage
	noeud.material_override = matiere(couleur)
	if not projette_une_ombre:
		noeud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return noeud


## Une roue : pneu, jante et moyeu. L'axe d'un CylinderMesh est vertical,
## il faut le coucher sur X pour qu'il roule dans le bon sens.
static func roue(parent: Node3D, rayon: float, position: Vector3) -> void:
	var pneu := cylindre(rayon, 0.16, Color(0.07, 0.07, 0.08), 14)
	pneu.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	pneu.position = position
	parent.add_child(pneu)

	var jante := cylindre(rayon * 0.52, 0.18, Color(0.72, 0.74, 0.78), 12)
	jante.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	jante.position = position
	parent.add_child(jante)

	var moyeu := cylindre(rayon * 0.16, 0.2, Color(0.30, 0.31, 0.34), 8)
	moyeu.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	moyeu.position = position
	parent.add_child(moyeu)


static func _incline(noeud: Node3D, angles: Vector3) -> Node3D:
	noeud.rotation_degrees = angles
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


## Un bidon d'essence jaune, celui qu'on voit a tous les coins de rue.
static func bidon() -> Node3D:
	var n := Node3D.new()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.98, 0.72, 0.10)
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = Color(0.9, 0.55, 0.05)
	m.emission_energy_multiplier = 0.5

	var corps := BoxMesh.new()
	corps.size = Vector3(0.55, 0.72, 0.34)
	var noeud := MeshInstance3D.new()
	noeud.mesh = corps
	noeud.material_override = m
	noeud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(noeud)

	_poser(n, Vector3(0.20, 0.16, 0.20), Color(0.20, 0.20, 0.22),
			Vector3(0.0, 0.44, 0.0))
	_poser(n, Vector3(0.36, 0.06, 0.06), Color(0.20, 0.20, 0.22),
			Vector3(0.0, 0.40, -0.14))
	_alleger_les_ombres(n, 1.0)
	return n


static func arbre(graine: int) -> Node3D:
	var n := Node3D.new()
	var hauteur := 2.4 + float(graine % 3) * 0.7
	_poser(n, Vector3(0.4, hauteur, 0.4), Color(0.40, 0.30, 0.20),
			Vector3(0.0, hauteur * 0.5, 0.0))
	var verts := [Color(0.22, 0.58, 0.24), Color(0.32, 0.68, 0.28),
			Color(0.16, 0.50, 0.22), Color(0.40, 0.72, 0.30)]
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
	var couleurs := [Color(0.95, 0.20, 0.18), Color(0.10, 0.42, 0.85),
			Color(1.00, 0.72, 0.08), Color(0.14, 0.70, 0.40),
			Color(0.92, 0.30, 0.66), Color(0.98, 0.50, 0.10)]
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
	# Les devantures de Bamako sont peintes, et vivement : ocre, terre
	# cuite, turquoise, bleu ciel. Le beige generique n'existe que dans les
	# jeux faits par des gens qui n'y sont jamais alles.
	var murs := [Color(0.90, 0.52, 0.18), Color(0.82, 0.28, 0.22),
			Color(0.16, 0.60, 0.58), Color(0.95, 0.76, 0.20),
			Color(0.28, 0.52, 0.78), Color(0.88, 0.44, 0.52),
			Color(0.42, 0.68, 0.34), Color(0.72, 0.36, 0.68)]
	var hauteur := 3.0 + float(graine % 5) * 1.2
	var largeur := 4.0 + float(graine % 3) * 1.2

	_poser(n, Vector3(largeur, hauteur, 6.0), murs[graine % murs.size()],
			Vector3(0.0, hauteur * 0.5, 0.0))
	# Toit de tole, gris-bleu : il tranche sur la facade et fait ressortir
	# la couleur au lieu de la noyer.
	_poser(n, Vector3(largeur + 0.4, 0.3, 6.4), Color(0.42, 0.46, 0.50),
			Vector3(0.0, hauteur + 0.15, 0.0))

	# Un etage en retrait, une fois sur trois : c'est ce qui casse
	# l'alignement des toits et empeche la rue d'avoir l'air d'un couloir.
	if graine % 3 == 0:
		var h2 := 2.2
		_poser(n, Vector3(largeur * 0.7, h2, 4.0),
				murs[(graine + 2) % murs.size()],
				Vector3(0.0, hauteur + h2 * 0.5 + 0.3, -0.6))

	# Auvent et enseigne cote rue.
	var enseignes := [Color(1.00, 0.24, 0.20), Color(0.10, 0.45, 0.95),
			Color(1.00, 0.78, 0.05), Color(0.10, 0.72, 0.40),
			Color(0.95, 0.35, 0.70)]
	_poser(n, Vector3(0.2, 0.9, 4.0), enseignes[graine % enseignes.size()],
			Vector3(-largeur * 0.5 - 0.1, 2.4, 0.0))
	if graine % 2 == 0:
		_poser(n, Vector3(1.6, 0.12, 4.4), Color(0.35, 0.35, 0.38),
				Vector3(-largeur * 0.5 - 0.8, 2.9, 0.0))
	return n


## Le vehicule du joueur, quel qu'il soit.
##
## Le garage ne sait pas ce qu'il affiche et la partie ne sait pas ce
## qu'elle pilote : les deux passent par ici. Ajouter un vehicule au
## catalogue ne demande donc de toucher ni l'un ni l'autre.
##
## Sur une voiture, la couleur choisie par le joueur ne peut pas aller sur
## un casque qu'on ne voit pas : elle va sur le toit, ou elle se remarque
## autant.
static func vehicule_joueur(modele: Dictionary,
		couleur_choisie: Color) -> Node3D:
	match str(modele.get("cle", "")):
		"taxi":
			var t := taxi()
			_poser(t, Vector3(0.7, 0.16, 0.5), couleur_choisie,
					Vector3(0.0, 2.0, 0.2))
			return t
		"sotrama":
			var v := sotrama()
			_poser(v, Vector3(1.4, 0.14, 2.6), couleur_choisie,
					Vector3(0.0, 2.28, 0.0))
			return v
	return moto(modele["couleur"], couleur_choisie)


## La moto du joueur, et son pilote.
##
## Vue de derriere a pleine vitesse, trois boites suffisaient. Dans le
## garage on la regarde de pres, et trois boites ne sont pas une moto :
## il faut des roues rondes, une fourche, un guidon, un pot, et quelqu'un
## dessus qui tienne le guidon.
##
## Les deux couleurs viennent du garage : la carrosserie depend de la moto
## achetee, le casque du choix du joueur.
static func moto(couleur_corps := Color(0.78, 0.16, 0.14),
		couleur_casque := Color(0.94, 0.86, 0.30)) -> Node3D:
	var n := Node3D.new()
	var sombre := Color(0.16, 0.16, 0.18)
	var chrome := Color(0.78, 0.80, 0.84)

	roue(n, 0.34, Vector3(0.0, 0.34, -0.86))
	roue(n, 0.34, Vector3(0.0, 0.34, 0.80))

	# Fourche avant : deux tubes inclines, qui montent vers le guidon.
	for cote in [-0.16, 0.16]:
		var tube := cylindre(0.045, 0.86, chrome, 8)
		tube.position = Vector3(cote, 0.66, -0.79)
		tube.rotation_degrees = Vector3(16.0, 0.0, 0.0)
		n.add_child(tube)

	# Garde-boue avant et arriere.
	_poser(n, Vector3(0.24, 0.06, 0.5), couleur_corps,
			Vector3(0.0, 0.70, -0.88))
	_poser(n, Vector3(0.26, 0.06, 0.55), couleur_corps,
			Vector3(0.0, 0.72, 0.82))

	# Bloc moteur, sous le reservoir.
	_poser(n, Vector3(0.34, 0.34, 0.52), Color(0.24, 0.25, 0.28),
			Vector3(0.0, 0.42, -0.08))
	for cote in [-0.22, 0.22]:
		var cache := cylindre(0.14, 0.08, Color(0.55, 0.56, 0.60), 10)
		cache.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		cache.position = Vector3(cote, 0.44, -0.08)
		n.add_child(cache)

	# Cadre, reservoir, selle.
	_poser(n, Vector3(0.18, 0.14, 1.5), sombre, Vector3(0.0, 0.62, 0.0))
	_poser(n, Vector3(0.36, 0.26, 0.62), couleur_corps,
			Vector3(0.0, 0.82, -0.28))
	_poser(n, Vector3(0.30, 0.10, 0.42), couleur_corps.lightened(0.32),
			Vector3(0.0, 0.96, -0.30))
	_poser(n, Vector3(0.34, 0.13, 0.62), Color(0.12, 0.12, 0.14),
			Vector3(0.0, 0.86, 0.30))
	# Carenages lateraux : ils donnent sa silhouette a la machine.
	for cote in [-0.20, 0.20]:
		_poser(n, Vector3(0.06, 0.30, 0.70), couleur_corps,
				Vector3(cote, 0.68, -0.20))

	# Guidon, poignees, retroviseurs, phare.
	_poser(n, Vector3(0.74, 0.055, 0.055), sombre, Vector3(0.0, 1.02, -0.74))
	for cote in [-0.34, 0.34]:
		_poser(n, Vector3(0.14, 0.07, 0.07), Color(0.10, 0.10, 0.12),
				Vector3(cote, 1.02, -0.74))
		var tige := cylindre(0.018, 0.16, sombre, 6)
		tige.position = Vector3(cote * 0.86, 1.12, -0.76)
		n.add_child(tige)
		_poser(n, Vector3(0.11, 0.07, 0.03), Color(0.60, 0.68, 0.76),
				Vector3(cote * 0.86, 1.20, -0.76))

	var phare := cylindre(0.13, 0.08, Color(0.98, 0.96, 0.80), 10)
	phare.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	phare.position = Vector3(0.0, 0.92, -0.94)
	n.add_child(phare)
	_poser(n, Vector3(0.10, 0.06, 0.04), Color(0.90, 0.16, 0.12),
			Vector3(0.0, 0.94, 1.02))

	# Pot d'echappement.
	var pot := cylindre(0.06, 0.8, chrome, 8)
	pot.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	pot.position = Vector3(0.19, 0.40, 0.36)
	n.add_child(pot)

	# Repose-pieds.
	for cote in [-0.26, 0.26]:
		_poser(n, Vector3(0.16, 0.04, 0.08), sombre,
				Vector3(cote, 0.38, 0.06))

	n.add_child(pilote(couleur_casque))
	_alleger_les_ombres(n)
	return n


## Coupe la projection d'ombre sur les petites pieces.
##
## Chaque objet qui projette une ombre est dessine deux fois : une fois a
## l'ecran, une fois dans la carte d'ombres. Une moto detaillee compte une
## trentaine de pieces, donc soixante appels de rendu — un sixieme du
## budget d'un telephone de 2021 pour une seule machine.
##
## Un retroviseur, un moyeu ou un repose-pied ne projettent rien qu'on
## puisse distinguer. Seules les grosses pieces gardent leur ombre, et la
## silhouette au sol reste la meme.
static func _alleger_les_ombres(racine: Node3D, seuil := 0.035) -> void:
	for enfant in racine.get_children():
		if enfant is MeshInstance3D:
			var forme: MeshInstance3D = enfant
			var taille: Vector3 = forme.mesh.get_aabb().size
			if taille.x * taille.y * taille.z < seuil:
				forme.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if enfant is Node3D:
			_alleger_les_ombres(enfant, seuil)


## Le pilote. Il doit tenir le guidon et plier les jambes, sinon il a
## l'air pose sur la moto au lieu d'etre dessus.
static func pilote(couleur_casque: Color) -> Node3D:
	var n := Node3D.new()
	var tenue := Color(0.20, 0.30, 0.58)
	var peau := Color(0.42, 0.28, 0.18)

	# Buste legerement penche vers l'avant.
	var buste := Node3D.new()
	buste.position = Vector3(0.0, 1.00, 0.14)
	buste.rotation_degrees = Vector3(-26.0, 0.0, 0.0)
	_poser(buste, Vector3(0.38, 0.46, 0.26), tenue, Vector3.ZERO)
	_poser(buste, Vector3(0.40, 0.12, 0.28), tenue.darkened(0.25),
			Vector3(0.0, -0.20, 0.0))
	n.add_child(buste)

	# Bras tendus vers les poignees.
	#
	# L'epaule est a (y 1,14 ; z -0,10), la poignee a (y 1,02 ; z -0,74) :
	# le bras descend de 0,12 sur 0,64 d'avancee, soit onze degres sous
	# l'horizontale. Une rotation POSITIVE autour de X releverait le bras,
	# puisqu'elle amene +Y vers +Z : il faut donc un angle negatif.
	for cote in [-1.0, 1.0]:
		var bras := Node3D.new()
		bras.position = Vector3(cote * 0.17, 1.14, -0.10)
		bras.rotation_degrees = Vector3(-11.0, cote * -11.0, 0.0)
		_poser(bras, Vector3(0.12, 0.12, 0.58), tenue, Vector3(0.0, 0.0, -0.29))
		_poser(bras, Vector3(0.11, 0.11, 0.13), peau, Vector3(0.0, 0.0, -0.62))
		n.add_child(bras)

	# Cuisse a plat, tibia qui redescend vers le repose-pied.
	for cote in [-1.0, 1.0]:
		_poser(n, Vector3(0.17, 0.19, 0.44), tenue,
				Vector3(cote * 0.19, 0.80, 0.22))
		var tibia := Node3D.new()
		tibia.position = Vector3(cote * 0.24, 0.62, 0.10)
		tibia.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
		_poser(tibia, Vector3(0.15, 0.40, 0.16), tenue, Vector3.ZERO)
		_poser(tibia, Vector3(0.15, 0.10, 0.26), Color(0.14, 0.13, 0.13),
				Vector3(0.0, -0.22, -0.05))
		n.add_child(tibia)

	# Casque : calotte, visiere sombre, et une aeration sur le dessus.
	var tete := Node3D.new()
	tete.position = Vector3(0.0, 1.40, -0.10)
	_poser(tete, Vector3(0.34, 0.34, 0.36), couleur_casque, Vector3.ZERO)
	_poser(tete, Vector3(0.30, 0.14, 0.06), Color(0.10, 0.11, 0.14),
			Vector3(0.0, 0.0, -0.18))
	_poser(tete, Vector3(0.36, 0.06, 0.20), couleur_casque.darkened(0.3),
			Vector3(0.0, 0.16, 0.02))
	n.add_child(tete)

	return n
