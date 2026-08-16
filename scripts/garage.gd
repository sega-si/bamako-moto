extends Node3D

## Le garage : l'ecran d'accueil, la moto qu'on choisit, la couleur du
## casque, le mode de jeu.
##
## L'interface est construite par le code plutot que posee dans l'editeur.
## Une liste de motos qui grandit ne demande alors aucune retouche : on
## ajoute une ligne au catalogue et le garage s'adapte.

const JEU := preload("res://scenes/jeu.tscn")

var _index := 0
var _apercu: Node3D
var _plateau: Node3D

var _nom: Label
var _description: Label
var _pouvoir: Label
var _champ_code: LineEdit
var _titre_couleur: Label
var _stats: Label
var _cagnotte: Label
var _bouton_action: Button
var _record: Label
var _boutons_mode: Array[Button] = []
var _pastilles: Array[Button] = []


func _ready() -> void:
	_index = maxi(0, _cle_vers_index(Donnees.moto_choisie))
	_construire_decor()
	_construire_interface()
	_rafraichir()


# --------------------------------------------------------------- la scene
func _construire_decor() -> void:
	var ciel := ProceduralSkyMaterial.new()
	ciel.sky_top_color = Color(0.11, 0.42, 0.88)
	ciel.sky_horizon_color = Color(0.62, 0.80, 0.94)
	ciel.ground_bottom_color = Color(0.72, 0.36, 0.19)
	ciel.ground_horizon_color = Color(0.86, 0.55, 0.30)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ciel
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	var monde := WorldEnvironment.new()
	monde.environment = env
	add_child(monde)

	var soleil := DirectionalLight3D.new()
	soleil.rotation_degrees = Vector3(-46.0, 42.0, 0.0)
	soleil.light_energy = 1.15
	soleil.light_color = Color(1.0, 0.96, 0.86)
	soleil.shadow_enabled = true
	add_child(soleil)

	# Un bout de laterite sous la moto : sans sol, elle flotte.
	var sol := Fabrique.boite(Vector3(34.0, 0.3, 34.0), Color(0.76, 0.38, 0.20),
			false)
	sol.position = Vector3(0.0, -0.15, -0.4)
	add_child(sol)

	_plateau = Node3D.new()
	add_child(_plateau)

	# Deux contraintes, resolues plutot que tatonnees.
	#
	# La largeur : en portrait, Godot garde la hauteur, donc le champ
	# horizontal vaut 0,5625 fois le vertical. A 32 degres, une moto de
	# deux metres ne tient dans la moitie de la largeur qu'a partir de
	# douze metres de recul.
	#
	# La hauteur : la ligne de mire doit passer sous la moto pour qu'elle
	# remonte dans le tiers superieur, au-dessus du panneau. A douze
	# metres, dix-huit degres de plongee visent -0,9 m.
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 3.0, 12.0)
	camera.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
	camera.fov = 32.0
	add_child(camera)


func _process(delta: float) -> void:
	# La moto tourne lentement sur elle-meme. C'est ce qui donne envie de
	# regarder celle d'apres.
	_plateau.rotation_degrees.y += 26.0 * delta


# ----------------------------------------------------------- l'interface
func _titre(texte: String, taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _bouton(texte: String, taille := 34) -> Button:
	var b := Button.new()
	b.text = texte
	b.add_theme_font_size_override("font_size", taille)
	b.custom_minimum_size = Vector2(0.0, 62.0)
	return b


func _construire_interface() -> void:
	var couche := CanvasLayer.new()
	add_child(couche)

	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 44)
	marge.add_theme_constant_override("margin_right", 44)
	marge.add_theme_constant_override("margin_top", 34)
	marge.add_theme_constant_override("margin_bottom", 44)
	couche.add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	colonne.add_child(_titre("BAMAKO MOTO", 54, Color(1.0, 0.84, 0.20)))

	_cagnotte = _titre("◉ 0", 34, Color(1.0, 0.84, 0.20))
	colonne.add_child(_cagnotte)

	# On laisse respirer : la moto en 3D occupe cette place.
	var vide := Control.new()
	vide.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(vide)

	var panneau := PanelContainer.new()
	var fond_panneau := StyleBoxFlat.new()
	fond_panneau.bg_color = Color(0.06, 0.07, 0.10, 0.82)
	fond_panneau.set_corner_radius_all(28)
	fond_panneau.set_content_margin_all(14)
	panneau.add_theme_stylebox_override("panel", fond_panneau)
	colonne.add_child(panneau)

	colonne = VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 6)
	panneau.add_child(colonne)

	# --- la moto
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 12)
	colonne.add_child(ligne)

	var precedent := _bouton("◀", 34)
	precedent.custom_minimum_size = Vector2(80.0, 62.0)
	precedent.pressed.connect(func(): _changer(-1))
	ligne.add_child(precedent)

	var milieu := VBoxContainer.new()
	milieu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(milieu)
	_nom = _titre("", 36, Color.WHITE)
	milieu.add_child(_nom)
	_stats = _titre("", 22, Color(0.86, 0.92, 1.0))
	_stats.autowrap_mode = TextServer.AUTOWRAP_OFF
	milieu.add_child(_stats)

	var suivant := _bouton("▶", 34)
	suivant.custom_minimum_size = Vector2(80.0, 62.0)
	suivant.pressed.connect(func(): _changer(1))
	ligne.add_child(suivant)

	# Le pouvoir en jaune, au-dessus de la description : c'est lui qui
	# decide de l'achat, pas la prose.
	_pouvoir = _titre("", 26, Color(1.0, 0.84, 0.20))
	colonne.add_child(_pouvoir)

	_description = _titre("", 21, Color(0.88, 0.88, 0.90))
	_description.custom_minimum_size = Vector2(0.0, 64.0)
	colonne.add_child(_description)

	_bouton_action = _bouton("", 32)
	_bouton_action.pressed.connect(_sur_action)
	colonne.add_child(_bouton_action)

	# --- le casque
	_titre_couleur = _titre("Casque", 24, Color(0.80, 0.84, 0.90))
	colonne.add_child(_titre_couleur)
	var couleurs := HBoxContainer.new()
	couleurs.add_theme_constant_override("separation", 8)
	couleurs.alignment = BoxContainer.ALIGNMENT_CENTER
	colonne.add_child(couleurs)
	for i in range(Catalogue.CASQUES.size()):
		var p := Button.new()
		p.custom_minimum_size = Vector2(52.0, 52.0)
		var fond := StyleBoxFlat.new()
		fond.bg_color = Catalogue.CASQUES[i]["couleur"]
		fond.set_corner_radius_all(26)
		p.add_theme_stylebox_override("normal", fond)
		p.add_theme_stylebox_override("hover", fond)
		p.add_theme_stylebox_override("pressed", fond)
		var indice := i
		p.pressed.connect(func(): _choisir_casque(indice))
		couleurs.add_child(p)
		_pastilles.append(p)

	# --- le mode
	colonne.add_child(_titre("Mode", 24, Color(0.80, 0.84, 0.90)))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	colonne.add_child(modes)
	for m in Catalogue.MODES:
		var b := _bouton(str(m["nom"]), 26)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cle := str(m["cle"])
		b.pressed.connect(func(): _choisir_mode(cle))
		modes.add_child(b)
		_boutons_mode.append(b)

	_record = _titre("", 24, Color(0.80, 0.84, 0.90))
	colonne.add_child(_record)

	# --- le defi
	#
	# Deux joueurs qui tapent le meme code affrontent exactement la meme
	# route. Il n'y a pas de serveur : le code EST la partie. On l'envoie
	# sur WhatsApp, l'autre le tape, et les scores se comparent.
	colonne.add_child(_titre("Défi d'un ami", 24, Color(0.80, 0.84, 0.90)))
	var ligne_defi := HBoxContainer.new()
	ligne_defi.add_theme_constant_override("separation", 8)
	colonne.add_child(ligne_defi)

	_champ_code = LineEdit.new()
	_champ_code.placeholder_text = "code reçu (ex. 483-921)"
	_champ_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_champ_code.add_theme_font_size_override("font_size", 28)
	_champ_code.custom_minimum_size = Vector2(0.0, 62.0)
	_champ_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_champ_code.text = Donnees.code_defi
	ligne_defi.add_child(_champ_code)

	var effacer := _bouton("✕", 26)
	effacer.custom_minimum_size = Vector2(70.0, 62.0)
	effacer.pressed.connect(func():
		_champ_code.text = ""
		Donnees.code_defi = ""
		Donnees.enregistrer()
		_rafraichir())
	ligne_defi.add_child(effacer)

	var jouer := _bouton("JOUER", 42)
	jouer.custom_minimum_size = Vector2(0.0, 88.0)
	jouer.pressed.connect(_jouer)
	colonne.add_child(jouer)


# ------------------------------------------------------------- les actions
func _cle_vers_index(cle: String) -> int:
	for i in range(Catalogue.MOTOS.size()):
		if Catalogue.MOTOS[i]["cle"] == cle:
			return i
	return 0


func _changer(pas: int) -> void:
	_index = wrapi(_index + pas, 0, Catalogue.MOTOS.size())
	_rafraichir()


func _choisir_casque(indice: int) -> void:
	Donnees.casque_choisi = indice
	Donnees.enregistrer()
	_rafraichir()


func _choisir_mode(cle: String) -> void:
	Donnees.mode_choisi = cle
	Donnees.enregistrer()
	_rafraichir()


func _sur_action() -> void:
	var moto: Dictionary = Catalogue.MOTOS[_index]
	var cle := str(moto["cle"])
	if Donnees.possede(cle):
		Donnees.moto_choisie = cle
		Donnees.enregistrer()
	else:
		Donnees.acheter(cle)
	_rafraichir()


func _jouer() -> void:
	# Le code saisi decide de la route. Vide, la partie est tiree au sort
	# comme d'habitude.
	Donnees.code_defi = _champ_code.text.strip_edges()
	Donnees.enregistrer()
	get_tree().change_scene_to_packed(JEU)


func _rafraichir() -> void:
	var moto: Dictionary = Catalogue.MOTOS[_index]
	var cle := str(moto["cle"])
	var possedee := Donnees.possede(cle)

	_nom.text = str(moto["nom"])
	# Sur une voiture il n'y a pas de casque : la couleur va sur le toit.
	_titre_couleur.text = "Casque" if str(moto.get("type", "moto")) == "moto" 			else "Couleur du toit"
	_pouvoir.text = "★ " + str(moto["pouvoir_nom"])
	_description.text = str(moto["pouvoir_texte"])
	_cagnotte.text = "◉ %d" % Donnees.pieces

	# Des barres plutot que des nombres : on compare deux motos d'un coup
	# d'oeil, ce qu'un « 1.22 » ne permet pas.
	_stats.text = "%s vitesse    %s tenue    %s" % [
			_barre(float(moto["vitesse"])),
			_barre(float(moto["tenue"])),
			"♥".repeat(int(moto["casse"]))]

	if possedee and Donnees.moto_choisie == cle:
		_bouton_action.text = "Choisie"
		_bouton_action.disabled = true
	elif possedee:
		_bouton_action.text = "Prendre celle-ci"
		_bouton_action.disabled = false
	else:
		_bouton_action.text = "Acheter — ◉ %d" % int(moto["prix"])
		_bouton_action.disabled = not Donnees.peut_acheter(cle)

	for i in range(_pastilles.size()):
		_pastilles[i].scale = Vector2.ONE * (1.18 if i == Donnees.casque_choisi else 1.0)

	for i in range(_boutons_mode.size()):
		_boutons_mode[i].disabled = Catalogue.MODES[i]["cle"] == Donnees.mode_choisi

	var mode := Catalogue.mode(Donnees.mode_choisi)
	_record.text = "%s — record %d" % [str(mode["description"]),
			Donnees.record(Donnees.mode_choisi)]
	if _champ_code != null and not _champ_code.text.strip_edges().is_empty():
		_record.text = "Défi %s — même route pour vous deux" 				% _champ_code.text.strip_edges()

	_montrer(moto)


func _barre(valeur: float) -> String:
	# Les valeurs utiles vont de 0,8 a 1,25 : on les etale sur cinq crans.
	var crans := clampi(int(round((valeur - 0.75) / 0.12)), 1, 5)
	return "▮".repeat(crans) + "▯".repeat(5 - crans)


func _montrer(moto: Dictionary) -> void:
	if _apercu != null:
		_apercu.queue_free()
	_apercu = Fabrique.vehicule_joueur(moto,
			Catalogue.CASQUES[Donnees.casque_choisi]["couleur"])
	# Legerement de trois quarts : une moto vue pile de face ne montre ni
	# sa longueur ni son pilote.
	_apercu.rotation_degrees.y = 25.0
	_plateau.add_child(_apercu)
