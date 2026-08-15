extends Node3D

## Un morceau d'avenue de vingt metres : le bitume, les bas-cotes, les
## bandes, et le decor des deux cotes.
##
## Le jeu n'en fabrique qu'une dizaine et les fait tourner en boucle : dès
## qu'un troncon passe derriere la camera, il repart devant. Rien n'est
## cree ni detruit pendant la partie, ce qui evite les a-coups.

const LONGUEUR := 20.0
const LARGEUR_VOIE := 3.0

var _variante := 0


func construire(variante: int) -> void:
	_variante = variante

	var bitume := Fabrique.boite(Vector3(LARGEUR_VOIE * 3.0, 0.2, LONGUEUR),
			Color(0.22, 0.22, 0.24), false)
	bitume.position = Vector3(0.0, -0.1, 0.0)
	add_child(bitume)

	for cote in [-1.0, 1.0]:
		var terre := Fabrique.boite(Vector3(7.0, 0.16, LONGUEUR),
				Color(0.62, 0.48, 0.33), false)
		terre.position = Vector3(cote * (LARGEUR_VOIE * 1.5 + 3.5), -0.12, 0.0)
		add_child(terre)

	_construire_bandes()
	_construire_decor()


func _construire_bandes() -> void:
	## Les huit bandes d'un troncon en un seul objet.
	##
	## Une par MeshInstance3D ferait huit appels de rendu par troncon, soit
	## une centaine pour l'avenue entiere. Un MultiMesh les dessine toutes
	## d'un coup : la carte recoit une forme et une liste de positions.
	var maillage := BoxMesh.new()
	maillage.size = Vector3(0.18, 0.02, 2.4)

	var lot := MultiMesh.new()
	lot.transform_format = MultiMesh.TRANSFORM_3D
	lot.mesh = maillage
	lot.instance_count = 8

	var n := 0
	for cote in [-0.5, 0.5]:
		for i in range(4):
			# Le pas de 5 divise les 20 metres du troncon : le raccord est
			# invisible au bouclage.
			lot.set_instance_transform(n, Transform3D(Basis(), Vector3(
					cote * LARGEUR_VOIE, 0.01,
					-LONGUEUR * 0.5 + 2.5 + float(i) * 5.0)))
			n += 1

	var noeud := MultiMeshInstance3D.new()
	noeud.multimesh = lot
	noeud.material_override = Fabrique.matiere(Color(0.92, 0.90, 0.80))
	noeud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(noeud)


func _construire_decor() -> void:
	# Sans decor lateral, rien ne defile dans la peripherie et la vitesse
	# ne se sent pas. C'est ce qui donne l'impression de rouler vite.
	var teintes := [Color(0.85, 0.72, 0.52), Color(0.78, 0.62, 0.46),
			Color(0.88, 0.80, 0.62), Color(0.72, 0.58, 0.44)]

	for cote in [-1.0, 1.0]:
		for i in range(2):
			var z := -LONGUEUR * 0.5 + 5.0 + float(i) * 10.0
			var rang := _variante * 4 + i + int(cote > 0.0) * 2

			if rang % 3 == 0:
				var poteau := Fabrique.boite(Vector3(0.35, 6.5, 0.35),
						Color(0.72, 0.70, 0.66))
				poteau.position = Vector3(cote * 6.6, 3.2, z)
				add_child(poteau)
				var bras := Fabrique.boite(Vector3(1.2, 0.16, 0.16),
						Color(0.72, 0.70, 0.66))
				bras.position = Vector3(cote * 6.0, 6.3, z)
				add_child(bras)
			else:
				var hauteur := 3.0 + float(rang % 4) * 1.3
				var mur := Fabrique.boite(Vector3(4.5, hauteur, 6.0),
						teintes[rang % teintes.size()])
				mur.position = Vector3(cote * 10.0, hauteur * 0.5, z)
				add_child(mur)
				# Un toit plus clair : deux volumes valent mieux qu'un
				# pave uniforme, et ca ne coute que douze triangles.
				var toit := Fabrique.boite(Vector3(4.8, 0.3, 6.3),
						Color(0.62, 0.56, 0.48))
				toit.position = Vector3(cote * 10.0, hauteur + 0.15, z)
				add_child(toit)
