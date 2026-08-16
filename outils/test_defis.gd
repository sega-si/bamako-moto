extends Node

## Verifie que les defis se tirent, avancent, se paient et expirent.
##
## L'expiration est la seule partie du jeu qui depend de l'horloge : elle
## ne se voit donc pas en jouant, et c'est exactement pour ca qu'il faut la
## tester.

func _ready() -> void:
	var echecs := 0

	# Le meme jour doit toujours donner les memes defis, sur tous les
	# appareils : c'est ce qui permet d'en parler entre amis.
	var a := Defis.du_jour()
	var b := Defis.du_jour()
	if a.size() != 3 or str(a[0]["texte"]) != str(b[0]["texte"]):
		push_error("les defis du jour ne sont pas stables")
		echecs += 1
	else:
		print("defis du jour, stables :")
		for d in a:
			print("   %-42s +%d pieces" % [d["texte"], d["recompense"]])

	# Trois defis differents, pas trois fois le meme.
	var cles := {}
	for d in a:
		cles[str(d["cle"])] = true
	if cles.size() != 3:
		push_error("deux defis du jour portent sur la meme chose")
		echecs += 1

	print("semaine : %s" % Defis.de_la_semaine()[0]["texte"])
	print("mois    : %s" % Defis.du_mois()[0]["texte"])
	print("il reste %s aujourd'hui, %s cette semaine, %s ce mois"
			% [Defis.temps_restant("jour"), Defis.temps_restant("semaine"),
			Defis.temps_restant("mois")])

	# Avancement et paiement.
	Donnees.pieces = 0
	Donnees.defis = {}
	Donnees.rafraichir_defis()
	var suivi: Dictionary = Donnees.liste_defis()[0]
	var genre := str(suivi["cle"])
	var cible := int(suivi["cible"])
	Donnees.avancer_defis(genre, cible - 1, genre == "record")
	if Donnees.pieces != 0:
		push_error("paye avant d avoir atteint la cible")
		echecs += 1
	Donnees.avancer_defis(genre, cible, genre == "record")
	if Donnees.pieces <= 0:
		push_error("defi atteint mais non paye")
		echecs += 1
	else:
		print("defi « %s » atteint : +%d pieces" % [genre, Donnees.pieces])

	# Expiration : une etiquette perimee doit balayer l'avancement.
	Donnees.defis["jour"]["etiquette"] = "j1970-01-01"
	Donnees.rafraichir_defis()
	var remis := true
	for d in Donnees.defis["jour"]["liste"]:
		if int(d["progres"]) != 0 or bool(d["paye"]):
			remis = false
	if not remis:
		push_error("un defi perime a garde son avancement")
		echecs += 1
	else:
		print("expiration : l avancement non termine est bien perdu")

	print("RESULTAT : %d echec(s)" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)
