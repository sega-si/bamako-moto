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

	print("RESULTAT : %d echec(s)" % echecs)
	get_tree().quit(1 if echecs > 0 else 0)
