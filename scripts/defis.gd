class_name Defis
extends RefCounted

## Les defis a duree limitee : trois par jour, un par semaine, un par mois.
##
## Leur interet n'est pas la recompense, c'est l'echeance. Un defi commence
## et se termine, qu'on l'ait fini ou non — c'est ce qui donne une raison
## de revenir demain plutot que dans trois semaines.
##
## Ils sont tires de la DATE et non du hasard : deux joueurs qui ouvrent le
## jeu le meme jour recoivent les memes defis. On peut donc en parler
## ensemble, ce qui vaut bien plus que trois objectifs personnels.

const MODELES := [
	{"cle": "pieces", "texte": "Ramasser %d pièces", "petit": 25, "moyen": 120, "grand": 500},
	{"cle": "distance", "texte": "Parcourir %d mètres en tout", "petit": 2500, "moyen": 12000, "grand": 45000},
	{"cle": "frolements", "texte": "Frôler %d véhicules", "petit": 20, "moyen": 90, "grand": 350},
	{"cle": "turbos", "texte": "Déclencher %d turbos", "petit": 4, "moyen": 18, "grand": 70},
	{"cle": "klaxons", "texte": "Klaxonner %d fois", "petit": 12, "moyen": 55, "grand": 200},
	{"cle": "parties", "texte": "Jouer %d parties", "petit": 5, "moyen": 22, "grand": 80},
	{"cle": "record", "texte": "Faire %d points en une seule partie", "petit": 700, "moyen": 1600, "grand": 3200},
]

const RECOMPENSES := {"jour": 30, "semaine": 150, "mois": 600}


## Une graine stable tiree d'un texte : le meme jour donne toujours les
## memes defis, sur tous les appareils.
static func _graine(etiquette: String) -> int:
	return absi(etiquette.hash())


static func _tirer(etiquette: String, combien: int, taille: String,
		duree: String) -> Array:
	var tirage := RandomNumberGenerator.new()
	# Un generateur a soi : la graine du defi partage par code ne doit pas
	# etre derangee, et reciproquement.
	tirage.seed = _graine(etiquette)

	var disponibles := range(MODELES.size())
	var choisis: Array = []
	for i in range(combien):
		var index: int = disponibles[tirage.randi() % disponibles.size()]
		disponibles.erase(index)
		var modele: Dictionary = MODELES[index]
		# Plus ou moins dix pour cent, pour que deux jours de suite ne
		# donnent pas exactement le meme chiffre.
		var cible := int(float(modele[taille]) * tirage.randf_range(0.9, 1.1))
		choisis.append({
			"cle": str(modele["cle"]),
			"texte": str(modele["texte"]) % cible,
			"cible": cible,
			"duree": duree,
			"recompense": int(RECOMPENSES[duree]),
		})
	return choisis


## Les etiquettes de periode. Elles servent a la fois de graine et de
## marqueur d'expiration : quand l'etiquette change, les defis changent et
## ce qui n'etait pas fini est perdu.
static func etiquette_jour() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "j%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


static func etiquette_semaine() -> String:
	var maintenant := Time.get_unix_time_from_system()
	# Le 1er janvier 1970 etait un jeudi ; on decale de quatre jours pour
	# que la semaine commence un lundi.
	var semaines := int((maintenant + 4 * 86400) / (7 * 86400))
	return "s%d" % semaines


static func etiquette_mois() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "m%04d-%02d" % [d["year"], d["month"]]


static func du_jour() -> Array:
	return _tirer(etiquette_jour(), 3, "petit", "jour")


static func de_la_semaine() -> Array:
	return _tirer(etiquette_semaine(), 1, "moyen", "semaine")


static func du_mois() -> Array:
	return _tirer(etiquette_mois(), 1, "grand", "mois")


## Combien de temps il reste, en clair. C'est cette phrase qui cree
## l'urgence, bien plus que la recompense.
static func temps_restant(duree: String) -> String:
	var d := Time.get_datetime_dict_from_system()
	if duree == "jour":
		var heures := 23 - int(d["hour"])
		if heures < 1:
			return "moins d'une heure"
		return "%d h" % heures
	if duree == "semaine":
		# get_datetime_dict_from_system donne 0 pour dimanche.
		var jour := int(d["weekday"])
		var restants := (8 - jour) % 7
		if restants == 0:
			return "aujourd'hui"
		return "%d jour%s" % [restants, "s" if restants > 1 else ""]
	var derniers: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var reste: int = derniers[int(d["month"]) - 1] - int(d["day"])
	reste = maxi(reste, 0)
	return "%d jour%s" % [reste, "s" if reste > 1 else ""]
