extends Node

## Ce que le joueur garde d'une partie a l'autre : sa cagnotte, ses motos,
## ses couleurs, ses records.
##
## Charge une fois au demarrage, ecrit a chaque changement. Un seul
## fichier, un seul endroit qui sait ou il est.

const FICHIER := "user://joueur.cfg"

var pieces: int = 0
var motos_possedees: Array[String] = ["vaillante"]
var moto_choisie: String = "vaillante"
var casque_choisi: int = 0
var mode_choisi: String = "sans_fin"
var records: Dictionary = {}


func _ready() -> void:
	charger()


func charger() -> void:
	var f := ConfigFile.new()
	if f.load(FICHIER) != OK:
		return
	pieces = int(f.get_value("joueur", "pieces", 0))
	moto_choisie = str(f.get_value("joueur", "moto", "vaillante"))
	casque_choisi = int(f.get_value("joueur", "casque", 0))
	mode_choisi = str(f.get_value("joueur", "mode", "sans_fin"))
	records = f.get_value("joueur", "records", {})

	# On repart du tableau enregistre, en garantissant que la moto de
	# depart y figure toujours : sinon un fichier abime laisserait le
	# joueur sans aucune moto.
	motos_possedees = ["vaillante"]
	for cle in f.get_value("joueur", "motos", []):
		if str(cle) not in motos_possedees:
			motos_possedees.append(str(cle))

	if moto_choisie not in motos_possedees:
		moto_choisie = "vaillante"


func enregistrer() -> void:
	var f := ConfigFile.new()
	f.set_value("joueur", "pieces", pieces)
	f.set_value("joueur", "motos", motos_possedees)
	f.set_value("joueur", "moto", moto_choisie)
	f.set_value("joueur", "casque", casque_choisi)
	f.set_value("joueur", "mode", mode_choisi)
	f.set_value("joueur", "records", records)
	f.save(FICHIER)


func possede(cle: String) -> bool:
	return cle in motos_possedees


func peut_acheter(cle: String) -> bool:
	return not possede(cle) and pieces >= int(Catalogue.moto(cle)["prix"])


func acheter(cle: String) -> bool:
	if not peut_acheter(cle):
		return false
	pieces -= int(Catalogue.moto(cle)["prix"])
	motos_possedees.append(cle)
	moto_choisie = cle
	enregistrer()
	return true


func record(mode: String) -> int:
	return int(records.get(mode, 0))


## Enregistre le resultat d'une partie. Renvoie vrai si c'est un record,
## pour que l'ecran de fin puisse le dire.
func terminer_partie(mode: String, score: int, gagnees: int) -> bool:
	pieces += gagnees
	var mieux := score > record(mode)
	if mieux:
		records[mode] = score
	enregistrer()
	return mieux
