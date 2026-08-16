extends Node

## Verifie la coherence du catalogue et de la sauvegarde.
##
## Un catalogue est une source d'erreurs silencieuses : une cle mal
## orthographiee ne se voit qu'au moment ou un joueur choisit cette
## moto-la, c'est-a-dire jamais pendant le developpement. Ce test essaie
## toutes les entrees et verifie que la sauvegarde fait bien l'aller-retour.

func _ready() -> void:
	var echecs := 0

	for m in Catalogue.MOTOS:
		var cle := str(m["cle"])
		if Catalogue.moto(cle)["nom"] != m["nom"]:
			push_error("moto introuvable par sa cle : " + cle)
			echecs += 1
		for champ in ["nom", "description", "prix", "vitesse", "tenue",
				"casse", "couleur"]:
			if not m.has(champ):
				push_error("%s : champ manquant « %s »" % [cle, champ])
				echecs += 1
		print("%-12s %4d pieces   vitesse %.2f   tenue %.2f   vies %d"
				% [cle, int(m["prix"]), float(m["vitesse"]),
				float(m["tenue"]), int(m["casse"])])

	for m in Catalogue.MODES:
		var cle := str(m["cle"])
		if Catalogue.mode(cle)["nom"] != m["nom"]:
			push_error("mode introuvable par sa cle : " + cle)
			echecs += 1
		print("%-12s duree %.0f s   depart x%.2f   densite x%.2f"
				% [cle, float(m["duree"]), float(m["depart"]),
				float(m["densite"])])

	# La moto de depart doit etre gratuite, sinon un nouveau joueur ne peut
	# rien faire.
	if int(Catalogue.MOTOS[0]["prix"]) != 0:
		push_error("la premiere moto du catalogue doit etre gratuite")
		echecs += 1

	# Aller-retour de la sauvegarde.
	Donnees.pieces = 1234
	Donnees.casque_choisi = 3
	Donnees.mode_choisi = "chrono"
	Donnees.records = {"chrono": 777}
	Donnees.enregistrer()
	Donnees.pieces = 0
	Donnees.charger()
	if Donnees.pieces != 1234 or Donnees.record("chrono") != 777 \
			or Donnees.casque_choisi != 3:
		push_error("la sauvegarde ne fait pas l'aller-retour")
		echecs += 1
	else:
		print("sauvegarde : aller-retour correct")

	# Chaque moto doit avoir un pouvoir, et deux motos ne doivent pas
	# partager le meme : sinon elles ne se distinguent que par des chiffres.
	var pouvoirs := {}
	for m in Catalogue.MOTOS:
		var p := str(m.get("pouvoir", ""))
		if p.is_empty():
			push_error("%s n a pas de pouvoir" % m["cle"])
			echecs += 1
		elif pouvoirs.has(p):
			push_error("pouvoir « %s » partage par %s et %s"
					% [p, pouvoirs[p], m["cle"]])
			echecs += 1
		else:
			pouvoirs[p] = str(m["cle"])
	print("pouvoirs distincts : %d sur %d motos"
			% [pouvoirs.size(), Catalogue.MOTOS.size()])

	# Le defi : un meme code doit toujours donner la meme graine, et deux
	# codes differents des graines differentes.
	var a := Donnees.graine_du_code("483-921")
	var b := Donnees.graine_du_code("483921")
	var c := Donnees.graine_du_code("483-922")
	if a != b:
		push_error("le tiret change la graine, il ne devrait pas")
		echecs += 1
	if a == c:
		push_error("deux codes differents donnent la meme route")
		echecs += 1
	if a == b and a != c:
		print("defi : meme code, meme route ; code different, autre route")

	print("RESULTAT : %d echec(s)" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)
