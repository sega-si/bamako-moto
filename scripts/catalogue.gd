class_name Catalogue
extends RefCounted

## Le catalogue des motos et des couleurs.
##
## Tout ce qui se debloque est decrit ici, et nulle part ailleurs. Ajouter
## une moto, c'est ajouter une ligne : ni le garage ni la partie n'ont a
## etre touches.
##
## Les noms sont inventes. Aucune marque reelle, jamais : un jeu qui
## affiche un nom de constructeur se fait retirer de la boutique.

## `vitesse` multiplie l'allure de depart et le plafond.
## `tenue` multiplie la vitesse de changement de voie.
## `casse` est le nombre de chocs encaisses avant la fin de la partie.
const MOTOS := [
	{
		"cle": "vaillante",
		"nom": "La Vaillante",
		"description": "Celle de tout le monde. Rien d'exceptionnel, rien à lui reprocher.",
		"prix": 0,
		"vitesse": 1.0,
		"tenue": 1.0,
		"casse": 1,
		"couleur": Color(0.78, 0.16, 0.14),
	},
	{
		"cle": "souple",
		"nom": "La Souple",
		"description": "Se faufile partout. Un peu lente, mais elle passe où les autres n'entrent pas.",
		"prix": 120,
		"vitesse": 0.92,
		"tenue": 1.45,
		"casse": 1,
		"couleur": Color(0.16, 0.60, 0.58),
	},
	{
		"cle": "rapide",
		"nom": "La Rapide",
		"description": "Va très vite et tourne mal. Les gros scores sont pour elle, les grosses chutes aussi.",
		"prix": 260,
		"vitesse": 1.22,
		"tenue": 0.82,
		"casse": 1,
		"couleur": Color(0.95, 0.62, 0.10),
	},
	{
		"cle": "cuirassee",
		"nom": "La Cuirassée",
		"description": "Encaisse un choc sans s'arrêter. Lourde, mais elle pardonne une erreur.",
		"prix": 420,
		"vitesse": 0.96,
		"tenue": 0.90,
		"casse": 2,
		"couleur": Color(0.35, 0.38, 0.44),
	},
	{
		"cle": "doree",
		"nom": "La Dorée",
		"description": "Rapide, maniable, et elle encaisse. Elle se mérite.",
		"prix": 900,
		"vitesse": 1.15,
		"tenue": 1.30,
		"casse": 2,
		"couleur": Color(0.95, 0.76, 0.18),
	},
]

## Couleurs de casque. Gratuites : la personnalisation qui ne coute rien
## est celle que tout le monde utilise, et c'est elle qui fait qu'un joueur
## se reconnait dans sa moto.
const CASQUES := [
	{"nom": "Jaune", "couleur": Color(0.94, 0.86, 0.30)},
	{"nom": "Rouge", "couleur": Color(0.90, 0.22, 0.20)},
	{"nom": "Bleu", "couleur": Color(0.20, 0.45, 0.90)},
	{"nom": "Vert", "couleur": Color(0.20, 0.72, 0.40)},
	{"nom": "Blanc", "couleur": Color(0.94, 0.94, 0.94)},
	{"nom": "Noir", "couleur": Color(0.14, 0.14, 0.16)},
	{"nom": "Rose", "couleur": Color(0.95, 0.40, 0.70)},
	{"nom": "Orange", "couleur": Color(0.98, 0.52, 0.10)},
]


## Les modes de jeu.
##
## `duree` a zero veut dire sans limite. `depart` multiplie la vitesse
## initiale, `densite` resserre l'espacement entre les vagues.
const MODES := [
	{
		"cle": "sans_fin",
		"nom": "Sans fin",
		"description": "Roule aussi loin que tu peux. Ça accélère tout seul.",
		"duree": 0.0,
		"depart": 1.0,
		"densite": 1.0,
	},
	{
		"cle": "chrono",
		"nom": "Chrono",
		"description": "Quatre-vingt-dix secondes. Chaque pièce ramassée en rajoute deux.",
		"duree": 90.0,
		"depart": 1.15,
		"densite": 0.9,
	},
	{
		"cle": "fou",
		"nom": "Circulation folle",
		"description": "Ça commence déjà vite et ça n'arrête pas d'arriver. Pour ceux qui s'ennuient.",
		"duree": 0.0,
		"depart": 1.6,
		"densite": 0.62,
	},
]


static func moto(cle: String) -> Dictionary:
	for m in MOTOS:
		if m["cle"] == cle:
			return m
	return MOTOS[0]


static func mode(cle: String) -> Dictionary:
	for m in MODES:
		if m["cle"] == cle:
			return m
	return MODES[0]
